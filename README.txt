#######################################################################
#   Copyright 2005-2022 SyoSil ApS
#   All Rights Reserved Worldwide
#
#   Licensed under the Apache License, Version 2.0 (the
#   "License"); you may not use this file except in
#   compliance with the License.  You may obtain a copy of
#   the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in
#   writing, software distributed under the License is
#   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied.  See
#   the License for the specific language governing
#   permissions and limitations under the License.
#######################################################################
#######################################################################
# README file for UVM scoreboard
#######################################################################
This file describes the basic contents of the UVM scoreboard release
and how to get started.

It is assumed that the UVM scoreboard is unpacked into the directory:
<UVMSCB>

In general, the UVM scoreboard is documented in the generated
documentation. See file:///<UVMSCB>/docs/manual/html/index.html for more
information.

Furthermore, the <UVMSCB>/docs/ also contains the latest paper
describing the fundamentals of the SyoSil UVM scoreboard.

*NOTE*: The documentation is also available in PDF (<UVMSCB>/docs/manual/pdf)

#######################################################################
# Directory structure
#######################################################################
.
├── docs            Documentation
│   ├── manual      User manual
│   │   ├──── pdf   Manual in PDF format
│   │   └──── html  Manual in HTML format
│   └── papers      DVCon papers presenting the SyoSil UVM SCB
├── src             SyoSil UVM SCB source code
├── tb              Simple example testbench
│  └── test        UVM Tests

#######################################################################
# Getting started
#######################################################################
To get started you need to be able to integrate and configure the UVM
scoreboard. This is documented in file:///<UVMSCB>/docs/manual/html/index.html

Examples:
Compilation examples for use with Mentor, Cadence or Synopys are
provided. The example will only work if you set the vendor by setting
a symbolic link:

  Mentor: ln -s Makefile.vendor.mentor Makefile.vendor

  Cadence: ln -s Makefile.vendor.cadence Makefile.vendor

  Synopsys: ln -s Makefile.vendor.synopsys Makefile.vendor

Once this is done, you can list the available targets by simply typing:

  make
