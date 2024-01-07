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
/// A test comparing the performance of using iterators vs using .find_first on a SV queue
//
// Preliminary results of average time [s] to find all M elements with M=50, num_iter=50
// N     | find_first | iterator
// ------+------------+--------
// 100   |  0.024     |  0.037
// 1000  |  0.135     |  0.283
// 10000 |  1.216     |  2.560
// 50000 |  6.093     | 13.632
// Conclusion: find_first is better than using iterators


//Preliminary results of average time to find all M elements with M=50,
//and also respecting the value of max_search_window
//average times over a number of different queue sizes and values of msw
// iterator: 3.7 seconds
// find_first on full queue: 6.6 seconds
// find_first on subqueue: 2.7 seconds
class cl_scb_test_queue_find_vs_search extends cl_scb_test_single_scb;
  //-------------------------------------
  // Non randomizable variables
  //-------------------------------------
  int N = 1000; //Number of items to generate
  int M = 50;    //Number of items to find


  // cl_tb_seq_item items[$]; //All N items that we generate
  // cl_tb_seq_item search_items[$]; //The M items that we're searching for
  // cl_syoscb_proxy_item_std proxy_items[$]; //Proxy items for the search items
  uvm_comparer comparer;


  //-------------------------------------
  // Randomizable variables
  //-------------------------------------
  randc int indices[]; //Indices in 'items' of the search items to find

  //-------------------------------------
  // UVM Macros
  //-------------------------------------
  `uvm_component_utils_begin(cl_scb_test_queue_find_vs_search)

  `uvm_component_utils_end

  //-------------------------------------
  // Constraints
  //-------------------------------------
  constraint co_indices {
    foreach(indices[i])
      indices[i] inside{[0:N-1]};
    indices.size() == M;
  }


  //-------------------------------------
  // Constructor
  //-------------------------------------
  function new(string name = "cl_scb_test_queue_find_vs_search", uvm_component parent = null);
    super.new(name, parent);

    this.comparer = new;
    cl_syoscb_comparer_config::set_verbosity(this.comparer, UVM_FULL);
  endfunction: new

  //-------------------------------------
  // Functions
  //-------------------------------------
  extern virtual function void pre_build();
  extern task                  run_phase(uvm_phase phase);

  extern function void         compare_iterator_and_find_first();
  extern function void         compare_msw();
  extern function void         compare_msw_approaches(int n, int m, int msw, int num_iter, ref real results[$]);
  extern function bit          compare_items(uvm_object primary_item, uvm_object sec_item);
  extern function void         log_time(string fname);
  extern function real         get_time_diff(string file1, string file2);

endclass: cl_scb_test_queue_find_vs_search

function void cl_scb_test_queue_find_vs_search::pre_build();
  super.pre_build();

  this.syoscb_cfgs.syoscb_cfg[0].set_enable_no_insert_check(1'b0);
endfunction: pre_build

task cl_scb_test_queue_find_vs_search::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  super.run_phase(phase);

  this.compare_iterator_and_find_first();
  // Commented out on purpose: This test takes a long time to run,
  // and does not contribute anything to regression testing.
  // Uncomment and run manually where necessary
  // this.compare_msw();

  phase.drop_objection(this);
endtask: run_phase

//Gets current time, stores it in the file named "fname"
function void cl_scb_test_queue_find_vs_search::log_time(string fname);
  $system($sformatf("date -Ins > %0s.time", fname));
endfunction: log_time

// Wrapper around compare_msw_approaches for storing results between runs
function void cl_scb_test_queue_find_vs_search::compare_msw();

  //AA of all different N, M, MSW values
  //Dim 1: N
  //Dim 2: msw
  //Dim 3: Approach
  //For all tests: M=50, num_iter=50
  real test_results[int][int][int];
  int Nvals[];
  int msw[];

  Nvals = '{100, 1000, 5000};
  msw = '{2, 4, 6, 8, 10};

  foreach(Nvals[i]) begin
    foreach(msw[j]) begin
      real results[$];
      compare_msw_approaches(Nvals[i], 50, Nvals[i]/msw[j], 20, results);
      test_results[Nvals[i]][msw[j]][0] = results[0];
      test_results[Nvals[i]][msw[j]][1] = results[1];
      test_results[Nvals[i]][msw[j]][2] = results[2];
    end
  end

  foreach(test_results[i,j,k]) begin
    $display("test_results[%0d][%0d][%0d]=%f", i, j, k, test_results[i][j][k]);
  end
endfunction: compare_msw

// Compares different approaches to finding items when max_search_window is non-zero
// Approach 1: Use an iterator to search over the queue instead of using find_first
// Approach 2: Use find_first, but if the found index is greater than msw, return null instead
// Approach 3: Copy the underlying queue, use SV queue-slicing to create a new queue with data from an old queue
function void cl_scb_test_queue_find_vs_search::compare_msw_approaches(int n, int m, int msw, int num_iter, ref real results[$]);
  real sum_approach1, sum_approach2, sum_approach3; //sum of times for each approach
  bit should_be_found[$];         //Indicates whether a given item should be found. Used for error checking
  cl_syoscb_item items[$];        //All N items in the queue
  cl_syoscb_item search_items[$]; //The M items we are searching for

  sum_approach1 = 0.0;
  sum_approach2 = 0.0;
  sum_approach3 = 0.0;

  //Reassigning to class variables to easily randomize indices
  this.N = n;
  this.M = m;

  $display("Testing MSW approaches with N=%0d, msw=%0d", n, msw);
  for(int iter=0; iter<num_iter; iter++) begin
    search_items.delete();
    should_be_found.delete();
    //items is not deleted since it points to the SV queue used in scoreboard

    //Generate the items to search for
    for(int i=0; i<n; i++) begin
      cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create($sformatf("ctsi_%0d", i));
      if(!ctsi.randomize()) begin
        `uvm_fatal("RAND", $sformatf("Unable to randomize ctsi %0d on iteration %0d", i, iter));
      end
      this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
    end

    //Get handle to the underlying queue
    begin
      cl_syoscb_queue_std queue_std;
      cl_syoscb_queue_base queue_base;

      queue_base = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
      if(!$cast(queue_std, queue_base)) begin
        `uvm_fatal("CAST", "Unable to cast Q1 to queue_std")
      end
      queue_std.get_native_queue(items);
    end

    //Generate the M indices that we wish to search for, store those M items in search_items
    //If that items index is outside of range, set should_be_found to 0
    void'(randomize(indices));
    foreach(indices[i]) begin
      search_items.push_back(items[indices[i]]);
      if(indices[i] < msw) begin
        should_be_found.push_back(1'b1);
      end else begin
        should_be_found.push_back(1'b0);
      end
    end

    //Start approach 1: Generate an iterator, find all items if they are within msw
    begin
      cl_syoscb_queue_iterator_base iter;
      cl_syoscb_proxy_item_base proxy;
      cl_syoscb_item sec_item;

      iter = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").create_iterator();
      log_time("a1_start");
      foreach(search_items[i]) begin
        void'(iter.first());

        while(iter.has_next() && iter.next_index() < msw) begin
          proxy = iter.next();
          sec_item = proxy.get_item();
          if(this.compare_items(search_items[i], sec_item)) begin
            //if match, verify that the code isn't sloppy. If not, break out, look for next item
            if(!should_be_found[i]) begin
              `uvm_fatal("APPROACH1", $sformatf("Iterator found item where it shouldn't. idx=%0d, msw=%0d", iter.previous_index(), msw))
            end
            break;
          end
          void'(iter.next());
        end
      end
      log_time("a1_end");
      void'(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1").delete_iterator(iter));
    end

    //Start approach 2. Use find_first_index, if index > msw, just discard it
    begin
      int found[$];
      log_time("a2_start");
      foreach(search_items[i]) begin
        found = items.find_first_index(x) with (this.compare_items(x, search_items[i]));
        if(found.size() != 1) begin
          `uvm_fatal("APPROACH2", $sformatf("Unable to find match for search item %0d. found.size=%0d", i, found.size()))
        end
        //At this point, should return item or null depending on size of msw, but that does not matter here
      end
      log_time("a2_end");
    end

    //Start approach 3. Copy the queue, search through that copy
    //To be realistic, we must make the copy every time
    begin
      cl_syoscb_item subqueue[$];
      int found[$];
      log_time("a3_start");
      foreach(search_items[i]) begin
        subqueue = items[0:msw-1];
        found = subqueue.find_first_index(x) with (this.compare_items(x, search_items[i]));
        if(found.size() == 1 && !should_be_found[i]) begin
          `uvm_fatal("APPROACH3", $sformatf("Found search_item[%0d] but was not supposed to find it. Iter=%0d, found.size()=%0d", i, iter, found.size()))
        end else if (found.size() != 1 && should_be_found[i]) begin
          `uvm_fatal("APPROACH3", $sformatf("Did not find search_item[%0d] but was supposed to find it. Iter=%0d, found.size=%0d", i, iter, found.size()))
        end
      end
      log_time("a3_end");
    end

    sum_approach1 += get_time_diff("a1_start", "a1_end");
    sum_approach2 += get_time_diff("a2_start", "a2_end");
    sum_approach3 += get_time_diff("a3_start", "a3_end");
    this.scb_env.syoscb[0].flush_queues_all();
    $display("Iteration %0d/%0d finished", iter+1, num_iter);
  end

  results.delete();
  results.push_back(sum_approach1);
  results.push_back(sum_approach2);
  results.push_back(sum_approach3);
endfunction: compare_msw_approaches

//Compares the performance of using an iterator vs. using find_first when
//searching through an entire queue for an item
function void cl_scb_test_queue_find_vs_search::compare_iterator_and_find_first();
  cl_tb_seq_item q[$]; //Queue for storing return value from find_first
  real sum_findfirst;  //total time used on find_first
  real sum_iterator;    //total time spent on iterator
  int num_iter;        //number of times to perform test
  cl_tb_seq_item items[$]; //All N items that we generate
  cl_tb_seq_item search_items[$]; //The M items that we're searching for
  cl_syoscb_proxy_item_std proxy_items[$]; //Proxy items for the search items

  sum_findfirst = 0.0;
  sum_iterator = 0.0;
  num_iter = 10;

  $display("Comparing iterator and find_first performance. N=%0d", this.N);
  for(int iter=0; iter<num_iter; iter++) begin
    q.delete();
    items.delete();
    proxy_items.delete();
    search_items.delete();

    //Generate N random seq. items
    for(int i=0; i<N; i++) begin
      cl_tb_seq_item ctsi = cl_tb_seq_item::type_id::create($sformatf("ctsi_%0d", i));
      if(!ctsi.randomize()) begin
        `uvm_fatal("RAND", $sformatf("Unable to randomize ctsi %0d", i))
      end
      //Store items in queue, insert all items into Q1 with P1 as producer
      items.push_back(ctsi);
      this.scb_env.syoscb[0].add_item("Q1", "P1", ctsi);
    end

    //Generate M random indices which we wish to find, store items from those indices in a new array
    void'(randomize(indices));
    foreach(indices[i]) begin
      cl_syoscb_proxy_item_std proxy = new;
      proxy.idx = indices[i];
      proxy.set_queue(this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1"));
      //Create proxy items for the iterator, search items for the find_first implementation
      proxy_items.push_back(proxy);
      search_items.push_back(items[indices[i]]);
    end

    //Time how long it takes using find_first
    log_time("time1");
    foreach(search_items[i]) begin
      q = items.find_first with (this.compare_items(item, search_items[i]));
      if(q.size() != 1) begin
        `uvm_fatal("FIND_FIRST", $sformatf("find_first did not find the requested search item. q.size=%0d", q.size()))
      end
    end
    log_time("time2");

    log_time("time3");
    //Time how long it takes using an iterator
    //We only create the iterator once
    foreach(proxy_items[i]) begin
      cl_syoscb_proxy_item_base proxy;
      cl_syoscb_queue_base queue;
      cl_syoscb_queue_iterator_base iter;
      bit found;

      queue = this.syoscb_cfgs.syoscb_cfg[0].get_queue("Q1");
      iter = queue.get_iterator("default");
      if(iter == null) begin
        iter = queue.create_iterator("default");
      end
      void'(iter.first());
      found = 1'b0;

      while(iter.has_next()) begin
        if(compare_items(proxy_items[i].get_item(), iter.next().get_item())) begin
          found = 1'b1;
          break;
        end
        void'(iter.next());
      end
      if(!found) begin
        `uvm_fatal("ITERATOR", $sformatf("Unable to find match for proxy_items[%0d]", i))
      end
    end
    log_time("time4");

    sum_findfirst += get_time_diff("time1", "time2");
    sum_iterator += get_time_diff("time3", "time4");

    //Flush out all items to ensure that we don't have orphan errors
    this.scb_env.syoscb[0].flush_queues_all();
    $display("Iteration %0d/%0d finished", iter+1, num_iter);
  end

  $display("num_iter: %0d, N=%0d, M=%0d", num_iter, this.N,  this.M);
  $display("Sum of FF times: %f. Avg of FF times: %f", sum_findfirst, sum_findfirst/real'(num_iter));
  $display("Sum of iterator times: %f. Avg of iterator times: %f", sum_iterator, sum_iterator/real'(num_iter));
  $display("\n\n");
endfunction: compare_iterator_and_find_first

function real cl_scb_test_queue_find_vs_search::get_time_diff(string file1, string file2);
  int f1, f2;
  string s1, s2;
  real t1, t2;
  real a;

  f1 = $fopen($sformatf("%0s.time", file1), "r");
  f2 = $fopen($sformatf("%0s.time", file2), "r");

  void'($fgets(s1, f1));
  void'($fgets(s2, f2));
  //date -Ins returns a string of the type
  //2022-01-24T08:48:50,131570320+0100
  //We wish to extract only the seconds-part of it, and replace the ',' with a '.'
  s1 = s1.substr(17, 28);
  s2 = s2.substr(17, 28);
  s1.putc(2, ".");
  s2.putc(2, ".");

  t1 = s1.atoreal();
  t2 = s2.atoreal();

  if(t2 < t1) begin //means that we crossed a minute marker
    a = 60.0 + t2 - t1;
  end else begin
    a = t2 - t1;
  end

   $fclose(f1);
   $fclose(f2);

  return a;
endfunction: get_time_diff

/// Compares two sequence items using an implicit comparer
/// Returns 1'b1 if the comparison is true, 1'b0 otherwise
function bit cl_scb_test_queue_find_vs_search::compare_items(uvm_object primary_item, uvm_object sec_item);
  if (primary_item.compare(sec_item, this.comparer)) begin
    `uvm_info("DEBUG", $sformatf(" Secondary item found"), UVM_FULL);
    return 1'b1;
  end else begin
    return 1'b0;
  end
endfunction: compare_items