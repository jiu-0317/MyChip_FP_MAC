# module
작성 순서는 data가 지나가는 순서와 동일함.  

top                : 모든 module 통합  
SPI_slave          : communication interface  
decoder            : master에서 받아온 값에서 각 field 분리  
dec_dff_formatter  : formatter로 들어갈 data저장  
input_formatter    : master에서 받아온 8bit E4M3/E5M2를 E5M3로 확장  
router             : command에 맞게 dff/fpu/acc 에 data와 command 전달  
weight_dff         : fpu로 들아갈 weight 저장  
input_dff          : fpu로 들어갈 input 저장  
fpu                : floating point 연산기  
fpu_dff            : fpu연산 결과 저장  
acc                : 모든 fpu연산 결과를 순차적으로 누적 합산  
acc_dff            : acc의 결과 저장  
output_formatter   : acc_dff의 값을 mode에 맞게 축소  

------------------------------------
# 수정된 설계 module
위 모듈을 일부 합쳐서 구성함.

TOP       : 
SPI_slave :
CONTROL   :
IR        :
W_I_RF    :
FPU       :
FPU_RF    :
ACC       :
ACC_R     :

------------------------------------
# SPI master-->slave data field
16 bit

command: 3 bit (5 commands)  
data:    8 bit (sign bit, E4M3/E5M2)  
address: 4 bit (command가 지정한 weight/input dff bank 에서 address가 0~8번 dff 지정.  
mode:    1 bit (output format을 E4M3/E5M2 지정)

------------------------------------
# mode
mode 0: E4M3  
mode 1: E5M2  
--> 확장 시 E4M3는 bias 보정 필요.

------------------------------------
# command
3 bit

LOAD_WEIGHT: 000  
LOAD_INPUT:  001  
COMPUTE:     010  
ACCUMULATE:  011  
READ_RESULT: 100  

------------------------------------
# control signal
datapath와 control을 나누어서 모든 control signal은 decoder가 제어.
