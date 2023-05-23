// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Antonio Mastrandrea (a.mastrandrea@unibo.it)

module i2cslave (
    input logic clk_i,
    input logic rst_ni,

    input  logic sda_i,
    output logic sda_o,
    output logic sda_oe,

    input  logic scl_i,
    // slave clock-stretching
    output logic scl_o,
    output logic scl_oe,

    output logic [31:0] data32_o,
    output logic        valid_o,
    output logic [ 3:0] strb_o,

    output logic [31:0] address_w_o,  // must be 8 bit

    input logic [31:0] data32_i,
    input logic        sample_data_i,

    output logic [31:0] address_r_o,
    output logic        valid_r_add_o,
	
	input logic [6:0] slave_address_i,
	input logic little_end_i,

    //other signal
    output logic test_start,
    output logic test_stop
);

  //sync sda_i and scl_i with voter:
  logic [1:0] r_sync_sda;  // SDA synchronizer
  logic [1:0] r_sync_scl;  // SCL synchronizer

  logic [2:0] r_filter_sda;  // SDA input filter with majority voting
  logic [2:0] r_filter_scl;  // SCL input filter with majority voting

  logic majvotSDA, majvotSCL;  // filtered and synchronized SCL and SDA inputs
  logic delmajvotSDA, delmajvotSCL;  // delayed versions of sSCL and sSDA

  logic start_cond, stop_cond;

  logic i2cBUSY,i2cBUSYnext;

  //logic inSDA; //data in read


  //parameter ADDRESS_slave = 8'b00011000;  //8'b01111001;

  logic [7:1] tempADDR;
  logic [7:1] n_tempADDR;
  
  logic enREADaddr;
  
  logic [7:1] tempADDRtest;
  logic checktestadd;
  
//  logic [7:1] slaveADDRESS = ADDRESS_slave;
  logic [7:1] slaveADDRESS;
  logic little_end;
 
  logic R_nW,n_R_nW;

  logic [7:0] testBYTE;

  logic endb;

  enum logic [3:0] {
    IDLE,
    ADDR_RnW,
    ACKwrite1,
	ACKwrite1_5,
    ACKwrite2,
    READ,
    READwaitAXI,
    READsendDATA,
    READwaitENDsendDATA,
    WRITEfirst,
    WRITEother,
    ACKread
  }
      CurSt, NexSt;

  //count bit address
  logic [4:0] countbitaddress;
  logic [4:0] Newcountbitaddress;

  //checks if the address is the i2c slave address
  logic checkADDRESS;

  logic addressOK;

  logic ACKwritebit;

  logic [7:0] initREG;
  logic [7:0] ninitREG;

  logic [7:0] pointerREG;

  logic [31:0] reg32;
  logic [31:0] reg32copy;
  logic [1:0] q;
  logic [1:0] qnext;
  logic [1:0] interstrb;
  logic intvalid;

  logic W_phase, n_W_phase;
  logic R_phase, n_R_phase;

  logic testnack;
  logic [3:0] strb_t;
  logic [3:0] strb_t_new;

  logic negedgeclki2c;
  logic READst, READstN;

  logic [31:0] sample_data32;

  logic [7:0] pointerread;

  logic activeI2Csend;
  logic finish_i2c_send;
  logic [7:0] inbyte;

  logic internaleSDAoe;
  logic outbread;

  logic sample_data_sync;
  
  
  logic [8:0] address_w_o_int;
  logic [8:0] address_w_o_int_next;
  
  assign address_w_o = address_w_o_int;

  //assign address to i2c slave:
  assign slaveADDRESS = slave_address_i;
  assign little_end =little_end_i;


  //output FIX to 0
  assign sda_o = 1'b0;
  assign scl_o = 1'b0;

  assign sda_oe = internaleSDAoe | outbread;

  //data output
  assign data32_o = reg32copy;
  assign valid_o = intvalid;
  assign strb_o = strb_t_new;

  //test:
  assign testBYTE = {tempADDR, R_nW};

  //test output
  assign test_start = start_cond;
  assign test_stop = stop_cond & i2cBUSY;  //only the right stop enable interrupt

/*
  assign tempADDRtest = tempADDR;
  
  //REMOVE this _ff
  always_ff @(posedge clk_i or negedge rst_ni) begin
     if (~rst_ni) begin
        checktestadd <= 1'b0;
     end else begin
        if (tempADDRtest == 7'h18) begin
           checktestadd <= 1'b1;
        end        
     end
  end
*/

  //SDA and SCl sync
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      r_sync_sda   <= 2'b11;
      r_sync_scl   <= 2'b11;

      r_filter_sda <= 3'b111;
      r_filter_scl <= 3'b111;
    end else begin
      r_sync_sda   <= {r_sync_sda[0], sda_i};
      r_sync_scl   <= {r_sync_scl[0], scl_i};

      r_filter_sda <= {r_filter_sda[1:0], r_sync_sda[1]};
      r_filter_scl <= {r_filter_scl[1:0], r_sync_scl[1]};
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      majvotSDA <= 1'b1;
      majvotSCL <= 1'b1;

      delmajvotSDA <= 1'b1;
      delmajvotSCL <= 1'b1;
    end else begin
      /*
           000 --> 0
           001 --> 0
           010 --> 0
           011 --> 1
           100 --> 0
           101 --> 1
           110 --> 1
           111 --> 1
         */
      majvotSDA <= &r_filter_sda[1:0] | &r_filter_sda[2:1] | (r_filter_sda[2] & r_filter_sda[0]);
      majvotSCL <= &r_filter_scl[1:0] | &r_filter_scl[2:1] | (r_filter_scl[2] & r_filter_scl[0]);

      //          |delS|   S   |      |delS|   S   |
      delmajvotSDA <= majvotSDA;  //                 _______       _____
      delmajvotSCL <= majvotSCL;  // detect   ______/          or       \______
    end
  end

  //start and stop detect
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      start_cond <= 1'b0;
      stop_cond  <= 1'b0;
    end else begin
      start_cond <= delmajvotSDA & ~majvotSDA & majvotSCL;
      stop_cond  <= ~delmajvotSDA & majvotSDA & majvotSCL;
    end
  end


  //          _____
  // detect        \______
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      negedgeclki2c <= 1'b0;
    end else begin
      negedgeclki2c <= delmajvotSCL & ~majvotSCL;
    end
  end


  // read sda input:
  //must be removed ???
  /*
   always_ff@(posedge clk_i or negedge rst_ni)
   begin
      if (~rst_ni)
      begin
         inSDA <= 1'b1;
      end
      else
      begin
         if (~delmajvotSCL & majvotSCL)
         begin
            inSDA <= majvotSDA;
         end
      end
   end
*/




  //arbitration lost:
  // stop detection but current state isn't IDLE
  // other ???
  //always_ff@(posedge clk_i or negedge rst_ni)
  //begin
  //arb_lost ??
  //end


  //transaction in progress if we are between the start and stop condition.
  //can we modify the memory from Pulp side if the i2c transaction is in progress? must check it
  //
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      i2cBUSY <= 1'b0;
    end else begin
      //i2cBUSY <= (start_cond | i2cBUSY) & ~stop_cond;
	  i2cBUSY <= i2cBUSYnext;
    end
  end

  always_comb begin
    i2cBUSYnext = (addressOK | i2cBUSY) & ~stop_cond;
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      addressOK <= 1'b0;
    end else begin
      if (checkADDRESS) begin
        if (tempADDR == slaveADDRESS) begin
          addressOK <= 1'b1;
        end
      end else begin
        addressOK <= 1'b0;
      end
    end
  end

  //state machine
  always_comb begin
    NexSt = CurSt;
    Newcountbitaddress = countbitaddress;
    checkADDRESS = 1'b0;
    //tempADDR = 7'b0000000;
    enREADaddr = 1'b0;
    ACKwritebit = 1'b0;

    //W_phase = 1'b0;
    //R_phase = 1'b0;

    n_tempADDR = tempADDR;
    n_R_nW = R_nW;
	n_R_phase = R_phase;
	n_W_phase = W_phase;

    READstN = READst;

    ninitREG = initREG;

    internaleSDAoe = 1'b0;
    scl_oe = 1'b0;

    endb = 1'b0;

    testnack = 1'b0;

    valid_r_add_o = 1'b0;

    activeI2Csend = 1'b0;

    unique case (CurSt)
      IDLE: begin
        READstN = 1'b0;

        n_W_phase = 1'b0;
        n_R_phase = 1'b0;
        Newcountbitaddress = 5'b01000;
        if (start_cond) begin
          NexSt = ADDR_RnW;
          Newcountbitaddress = 5'b01000;
          n_tempADDR = 7'b0000000;
          enREADaddr = 1'b0;
          n_R_nW = 0;  //default write

        end
      end

      ADDR_RnW: begin
        READstN = 1'b0;

        //NexSt = ADDR_RnW;
        if (~delmajvotSCL & majvotSCL) begin
          if (countbitaddress > 5'b00001) //from 7 to 2
          begin
            n_tempADDR[countbitaddress-1] = majvotSDA;
            enREADaddr = 1'b1;
            Newcountbitaddress = countbitaddress - 5'b00001;
          end
          else if (countbitaddress == 5'b00001) //read n_write bit
          begin
            //check address
            checkADDRESS = 1'b1;
            //R_nW bit:
            n_R_nW = majvotSDA;
            Newcountbitaddress = countbitaddress - 5'b00001;
          end
        end
        
        if (addressOK & countbitaddress == 5'b00000) begin
          NexSt = ACKwrite1;
          Newcountbitaddress = 5'b01000;

        end else if (~addressOK & countbitaddress == 5'b00000) begin
          NexSt = IDLE;
          testnack = 1'b1;
        end
      end

      ACKwrite1: begin

        endb = 1'b1;
        NexSt = ACKwrite1_5;
		if (delmajvotSCL & ~majvotSCL) begin
			NexSt = ACKwrite2;
		end
      end
	  
	  ACKwrite1_5: begin

        endb = 1'b0;

		if (delmajvotSCL & ~majvotSCL) begin
			NexSt = ACKwrite2;
		end
      end

      ACKwrite2: begin

        //NexSt = ACKwrite;
        internaleSDAoe = 1'b1;
        if (delmajvotSCL & ~majvotSCL) begin
            internaleSDAoe = 1'b0;
        end
        
        ACKwritebit = 1'b1;
        if (stop_cond) begin
          NexSt = IDLE;
        end
        if (delmajvotSCL & ~majvotSCL) begin

          begin
            if (R_phase==0 & W_phase==0) //first time on read or write phase
                    begin
              if (R_nW == 1'b1) //Read
                       begin
                NexSt = READ;
              end
                       else //write
                       begin
                NexSt = WRITEfirst;
              end
            end
                    else // no address and R_nW phase
                    begin
              if (R_phase) begin
                NexSt = WRITEother;
              end else if (W_phase) begin
                NexSt = WRITEother;
                //R_phase = 1'b1;
              end
            end
          end
        end
      end

      READ: begin
        READstN = 1'b1;
        if (stop_cond) begin
          NexSt = IDLE;
        end else begin
          if (negedgeclki2c) begin
//           scl_oe = 1'b1;  //hold clock to zero until data from Axi is ready
            NexSt = READwaitAXI;
            valid_r_add_o = 1'b1;
          end else begin
            NexSt = READ;
          end
        end
      end

      READwaitAXI: begin
        READstN = 1'b1;
        if (stop_cond) begin
          NexSt = IDLE;
        end else begin
//          scl_oe = 1'b1;
          if (sample_data_i) begin
            NexSt = READsendDATA;
          end
        end
      end

      READsendDATA: begin
        READstN = 1'b1;
        activeI2Csend = 1;
        NexSt = READwaitENDsendDATA;

      end

      READwaitENDsendDATA: begin
        READstN = 1'b1;
        if (finish_i2c_send) begin
          READstN = 1'b0;
          NexSt   = ACKread;
        end else begin
          NexSt = READwaitENDsendDATA;
        end
      end

      WRITEfirst: //start address in the memory
           begin
        READstN = 1'b0;
        if (stop_cond) begin
          NexSt = IDLE;
        end else if (~delmajvotSCL & majvotSCL) begin
          if (countbitaddress > 5'b00001) //
                 begin
            ninitREG[countbitaddress-1] = majvotSDA;
            Newcountbitaddress = countbitaddress - 5'b00001;
          end
                 else
                 if (countbitaddress == 5'b00001) //read n_write bit
                 begin
            //ninitREG = {initREG,majvotSDA};
            ninitREG[countbitaddress-1] = majvotSDA;
            Newcountbitaddress = 5'b01000;
            NexSt = ACKwrite1;
            n_W_phase = 1'b1;
          end
        end

      end

      WRITEother:  //write data. Start from
           begin
        READstN = 1'b0;

        if (stop_cond) begin
          NexSt = IDLE;
        end else if (~delmajvotSCL & majvotSCL) begin
          n_W_phase = 1'b0;
          if (countbitaddress > 5'b00001) //
                 begin
            ninitREG[countbitaddress-1] = majvotSDA;
            Newcountbitaddress = countbitaddress - 5'b00001;
          end
                 else
                 if (countbitaddress == 5'b00001) //read n_write bit
                 begin
            ninitREG[countbitaddress-1] = majvotSDA;
            //Newcountbitaddress = countbitaddress - 5'b00001;
            Newcountbitaddress = 5'b01000;
            NexSt = ACKwrite1;
            n_R_phase = 1'b1;
          end
        end
      end

      ACKread: begin
        //TODO
        NexSt = IDLE;
      end
      default: begin
        NexSt = IDLE;
     
      end
    endcase

  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      R_nW <= 1'b0;
	  W_phase <= 1'b0;
	  R_phase <= 1'b0;
    end else begin
      R_nW <= n_R_nW;
	  W_phase <= n_W_phase;
	  R_phase <= n_R_phase;
    end
  end

   

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      READst <= 1'b0;
    end else begin
      READst <= READstN;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      sample_data32 <= 32'b0;
      sample_data_sync <= 1'b0;
    end else begin
      if (sample_data_i) begin
        sample_data_sync <= 1'b1;
        sample_data32 <= data32_i;
      end else begin
        sample_data_sync <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      tempADDR <= 7'b000_0000;
    end else begin
      tempADDR <= n_tempADDR;
    end
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      CurSt <= IDLE;
      countbitaddress <= 5'b01000;
      initREG <= 8'b0000_0000;
    end else begin
      CurSt <= NexSt;
      countbitaddress <= Newcountbitaddress;
      initREG <= ninitREG;
    end
  end


  //change pointer reg
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      pointerREG <= 8'b0000_0000;
    end else begin
      if (W_phase) begin
        pointerREG <= initREG - 1;
      end else if (R_phase && endb) begin
        pointerREG <= pointerREG + 1;
      end
    end
  end

  //address_r_o must be increase by 4 after read or not: add configuration bit for this purpose!!!
  //now the address is not incremented
  assign pointerread = pointerREG + 1;
  assign address_r_o = {pointerread[7:2], 2'b00};

  always_comb begin
    if (pointerread[1:0] == 2'b00) begin
      inbyte = sample_data32[7:0];
    end else if (pointerread[1:0] == 2'b01) begin
      inbyte = sample_data32[15:8];
    end else if (pointerread[1:0] == 2'b10) begin
      inbyte = sample_data32[23:16];
    end else begin
      inbyte = sample_data32[31:24];
    end
  end


  
 always_comb begin
   qnext = q;
   if (endb && (R_phase || W_phase)) begin
     qnext = q + 1;
   end else if (start_cond) begin
     qnext = 0;
   end 
 end

 always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
       q <= 2'b00;
    end else begin
       q <= qnext;
    end
    
 end



  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      reg32       <= 32'h0000_0000;
      reg32copy   <= 32'h0000_0000;
      
      interstrb   <= 2'b00;
      intvalid    <= 1'b0;
//      address_w_o_int <= 32'b0;
    end else begin
      intvalid <= 1'b0;
      if (endb && (R_phase || W_phase)) begin
            
            if (q == 2'b00) begin
              reg32copy <= reg32;
              interstrb <= 2'b00;
              if (R_phase) begin
                    intvalid <= 1'b1;
 //                   address_w_o_int <= address_w_o_int_next + 4;
              end
            end
			if (little_end==1'b0) begin
				reg32 <= {initREG,reg32[31:8]};
			end else begin
				reg32 <= {reg32[23:0], initREG};
			end
      end else begin
        if (start_cond) begin
             
              reg32copy   <= 32'h0000_0000;
              reg32       <= 32'h0000_0000;
              intvalid    <= 1'b0;
//              address_w_o_int_next <= 0;
        end else if (stop_cond && i2cBUSY) begin
              if (q != 2'b00) begin
					if (little_end==1'b0) begin //little endian
						if(q==2'b01) begin
							reg32copy <= {24'b0,reg32[31:24]};
						end else if (q==2'b10) begin
							reg32copy <= {16'b0,reg32[31:16]};
						end else begin
							reg32copy <= {8'b0,reg32[31:8]};
						end
					end else begin //big endian
						if(q==2'b01) begin
							reg32copy <= {24'b0,reg32[31:24]};
						end else if (q==2'b10) begin
							reg32copy <= {16'b0,reg32[31:16]};
						end else begin
							reg32copy <= {8'b0,reg32[31:8]};
						end
					end
	//                address_w_o_int_next <= address_w_o_int + 4;
					interstrb <= q;
					intvalid <= 1'b1;
              end else begin
					if (little_end==1'b0) begin
						reg32copy <= reg32;
					end else begin
						reg32copy <= reg32;
					end
	//                address_w_o_int_next <= address_w_o_int + 4;
					interstrb <= 2'b00;
					intvalid <= 1'b1;
              end
        end
        
      end


    end
  end


  
 always_comb begin
   address_w_o_int_next = address_w_o_int;
   if (endb && (R_phase || W_phase)) begin
      if (q == 2'b00) begin
         if (R_phase) begin
               address_w_o_int_next = address_w_o_int + 4;
         end
      end
   end else begin 
      if (start_cond) begin
         address_w_o_int_next = 0;
      end else
	  if (stop_cond) begin
         address_w_o_int_next = address_w_o_int + 4;
      end  
	  
   end
 end

 always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
       address_w_o_int <= 0;
    end else begin
       address_w_o_int <= address_w_o_int_next;
    end
    
 end
    


  always_comb begin
    strb_t = strb_t_new;
    if (intvalid) begin
      if (interstrb == 1) strb_t = 4'b0001;
      else if (interstrb == 2) strb_t = 4'b0011;
      else if (interstrb == 3) strb_t = 4'b0111;
      else strb_t = 4'b1111;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      strb_t_new <= 4'b1111;
    end else if (intvalid) begin
      strb_t_new <= strb_t;
    end

  end

  //i2c send byte logic
  i2csend i_i2csend (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .clki2c_i(scl_i),

      .enable_i(sample_data_sync),
      .inB_i   (inbyte),
      .active_i(activeI2Csend),

      .bitout_o(outbread),

      .endsendbyte_o(finish_i2c_send)
  );


endmodule
