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

////////////////////////////////////////////////////////////////////////////
// Type definitions
////////////////////////////////////////////////////////////////////////////
typedef enum {TXT,XML} t_dump_type;

typedef enum {SYOSCB_QUEUE_STD,
              SYOSCB_QUEUE_MD5,
              SYOSCB_QUEUE_USER_DEFINED} t_scb_queue_type;

typedef enum {SYOSCB_COMPARE_IO,
              SYOSCB_COMPARE_IO2HP,
              SYOSCB_COMPARE_IOP,
              SYOSCB_COMPARE_OOO,
              SYOSCB_COMPARE_USER_DEFINED} t_scb_compare_type;

typedef enum {SYOSCB_COMPARE_NOT_GREEDY,
              SYOSCB_COMPARE_GREEDY} t_scb_compare_greed;

typedef enum {SYOSCB_PRINTER_TABLE,
              SYOSCB_PRINTER_TREE,
              SYOSCB_PRINTER_LINE,
              SYOSCB_PRINTER_XML} t_printer_type;

typedef enum { SYOSCB_HASH_COMPARE_NO_VALIDATION,
               SYOSCB_HASH_COMPARE_VALIDATE_MATCH,
               SYOSCB_HASH_COMPARE_VALIDATE_NO_MATCH,
               SYOSCB_HASH_COMPARE_VALIDATE_ALL} t_hash_compare_check;

////////////////////////////////////////////////////////////////////////////
// Local Parameters
////////////////////////////////////////////////////////////////////////////
localparam int unsigned MIN_FIRST_COLUMN_WIDTH  = 8;
localparam int unsigned GLOBAL_REPORT_INDENTION = 2;

localparam int unsigned MD5_HASH_DIGEST_WIDTH   = 128;

////////////////////////////////////////////////////////////////////////////
// Macro Definitions
////////////////////////////////////////////////////////////////////////////
let max(a,b)      = (a > b) ? a : b;
let min_width(sl) = ((sl>pk_syoscb::MIN_FIRST_COLUMN_WIDTH)? sl : pk_syoscb::MIN_FIRST_COLUMN_WIDTH);