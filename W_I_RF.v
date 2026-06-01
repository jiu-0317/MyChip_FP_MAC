// 기존의 router와 weight/input dff를 통합했다. 

/*
| Port          | Dir | Width | Description                   
| ------------- | --- | ----- | ----------------------------- 
| i_clk, i_rstn | in  | 1     |                               
| i_clear_valid | in  | 1     |
| i_w_wen       | in  | 1     | weight write enable (w RF 지정) 
| i_i_wen       | in  | 1     | input write enable (i RF 지정)  
| i_addr        | in  | 4     | 몇번 register에 쓸지 지정            
| i_data        | in  | 9     | 쓸 data                        
| o_w_all_valid | out | 1     | 모든 weight register가 다 찼으면 1   
| o_i_all_valid | out | 1     | 모든 input register가 다 찼으면 1    
| o_w_data      | out | 9x9   | weight 저장                    
| o_i_data      | out | 9x9   | input 저장                      
*/

`timescale 1ns / 1ps

module W_I_RF (
    input            i_clk, 
    input            i_rstn,
    // input            i_clear_valid,
    input            i_w_wen,
    input            i_i_wen,
    input      [3:0] i_addr,
    input      [8:0] i_data,
    // output wire      o_w_all_valid,
    // output wire      o_i_all_valid,
    output reg [8:0] o_w_data [8:0],
    output reg [8:0] o_i_data [8:0]
);

// reg [8:0] w_all_set;
// reg [8:0] i_all_set;
always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
        for (k = 0; k < 9; k = k + 1) begin
            o_w_data[k] <= 9'd0;
            o_i_data[k] <= 9'd0;
        end
    end else begin
        if (i_w_wen && i_addr < 9)
            o_w_data[i_addr] <= i_data;
        else if (i_i_wen && i_addr < 9)
            o_i_data[i_addr] <= i_data;
    end
end

// assign o_w_all_valid = &w_all_set;
// assign o_i_all_valid = &i_all_set;
    
endmodule