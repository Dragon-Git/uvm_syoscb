//----------------------------------------------------------------------
//   Copyright 2005-2022 SyoSil ApS
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------
//Defining the actions that each iterator can take in the test
typedef enum { NEXT, PREV, FIRST, LAST, INSERT, DELETE } iterator_action_t;

//A helper object to use in the test defined below
//Used to keep track of operations happening on the queue, allowing us to reconstruct and validate that all queues performed correctly
class cl_scb_test_iterator_correctness_helper_object extends uvm_object;
  int index;
  iterator_action_t op;

  `uvm_object_utils_begin(cl_scb_test_iterator_correctness_helper_object)
    `uvm_field_int(index, UVM_DEFAULT)
    `uvm_field_enum(iterator_action_t, op, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "cl_scb_test_iterato_deadlock_helper_object");
    super.new(name);
  endfunction: new

  function string convert2string();
    return {this.op.name(), $sformatf(" %3d", this.index)};
  endfunction: convert2string
endclass

/// Test to ensure that multiple iterators on the same queue won't deadlock and are performing correctly.
/// At the end, validates that the correct items have been removed/inserted
//Note that on test finish, number of Q1 insertions/matches won't match number of Q2 insertions/matches
//This is on purpose, since every deleted item counts as a "match" for the SCB
class cl_scb_test_iterator_correctness extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------

  //All operations that are performed on the queue
  cl_scb_test_iterator_correctness_helper_object operations[$];

  int NUM_ITEMS; //Number of items to start with
  int NUM_ITERS; //Number of iterators to create
  int NUM_ACTIONS; //Number of actions each iterator should perform

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_iterator_correctness)

  `uvm_component_utils_end

  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_iterator_correctness", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern task main_phase(uvm_phase phase);
  extern task use_iterator(int id);


endclass: cl_scb_test_iterator_correctness

//Spin up an iterator, use it to perform a series of operations on the queue.
//Tracks all insert/delete operations in this.operations
task cl_scb_test_iterator_correctness::use_iterator(int id);
  iterator_action_t action;
  cl_syoscb_queue_iterator_base iter;
  cl_syoscb_queue_base q = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");

  #($urandom_range(100, 1)); //Wait for some random amount before creating the iterator
  iter = q.create_iterator();

  for(int i=0; i<this.NUM_ACTIONS; i++) begin
    if(!std::randomize(action)) begin
      `uvm_fatal("RAND", "Unable to randomize action to take")
    end

    case (action)
      NEXT:  if(iter.has_next()) void'(iter.next());
      PREV:  if(iter.has_previous()) void'(iter.previous());
      FIRST: void'(iter.first());
      LAST:  void'(iter.last());
      INSERT: begin
        //Create sequence item and tracker object, track operation and insert item
        cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
        cl_scb_test_iterator_correctness_helper_object help = new;
        help.index = this.operations.size(); //use operations.size() to get a unique index for every value
        help.op = INSERT;
        ctsi.int_a = this.operations.size();

        this.operations.push_back(help);
        this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
      end
      DELETE: begin
        cl_syoscb_proxy_item_base proxy;
        cl_scb_test_iterator_correctness_helper_object help;

        //When deleting, we try to remove the item in front.
        //Only if that is impossible do we step back once and then delete the item
        if(iter.has_next()) begin
          proxy = iter.next();
        end else begin
          void'(iter.previous());
          proxy = iter.next();
        end

        //Create tracker object, track operation and delete item at current iterator index
        help = new;
        help.index = iter.previous_index(); //TODO: Requires reworking
        help.op = DELETE;
        this.operations.push_back(help);
        void'(q.delete_item(proxy));
      end
    endcase
    //Below line commented out on purpose. Uncomment for debug printout if test breaks
    // $display("[%0d](%3t) %s, %0d/%0d", id, $time, action.name, iter.next_index(), q.get_size()-1);

    #($urandom_range(10,1)); //Wait for some random amount
  end

endtask: use_iterator

task cl_scb_test_iterator_correctness::main_phase(uvm_phase phase);
  int result[$];

  phase.raise_objection(this);
  super.main_phase(phase);

  NUM_ITEMS = 50;
  NUM_ITERS = 10;
  NUM_ACTIONS = 100;

  //Add some starting items to Q1 that we can iterate over
  //Also track all of these items so we can reconstruct later
  for(int i=0; i<this.NUM_ITEMS; i++) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    cl_scb_test_iterator_correctness_helper_object help = new;

    help.index = i;
    help.op = INSERT;
    this.operations.push_back(help);

    ctsi.int_a = i;
    this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
  end

  //Spin up multiple threads iterating over Q1, performing random operations
  for(int i=0; i<this.NUM_ITERS; i++) begin
    fork
      //Must create new value k such that it is not bound to the value of i declared outside of fork
      automatic int k = i;
      this.use_iterator(k);
    join_none
  end
  wait fork; //Must wait after join_none to ensure main_phase doesn't end prematurely

  //Reconstruct all operations
  //After this foreach loop, result should contain all indices still present in queue
  foreach(this.operations[i]) begin
    if(this.operations[i].op == INSERT) begin //insertion
      result.push_back(this.operations[i].index);
    end else if(this.operations[i].op == DELETE) begin
      result.delete(this.operations[i].index);
    end else begin
      `uvm_error("TEST", $sformatf("Bad enum in helper object. str=%s, value=%0d", this.operations[i].op.name(), this.operations[i].op))
    end
  end

  //For all remaining indices, add to Q2
  //Everything should hopefully match up
  foreach(result[i]) begin
    cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create("ctsi");
    ctsi.int_a = result[i];
    this.scb_env.syoscb[0].add_item("Q2", "P1", ctsi);
  end

  phase.drop_objection(this);
endtask: main_phase