export BOARD=zcu102
export XILINX_PART=xczu9eg-ffvb1156-2-e
export XILINX_BOARD=xilinx.com:zcu102:part0:3.3
export FC_CLK_PERIOD_NS=50 # 20MHz
export PER_CLK_PERIOD_NS=100 # 10MHz
export SLOW_CLK_PERIOD_NS=30517 # 32kHz
$(info Setting environment variables for $(BOARD) board)
$(info FC_CLK_PERIOD_NS=$(FC_CLK_PERIOD_NS))
$(info PER_CLK_PERIOD_NS=$(PER_CLK_PERIOD_NS))
$(info SLOW_CLK_PERIOD_NS=$(SLOW_CLK_PERIOD_NS))
