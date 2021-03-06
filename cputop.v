`timescale 1ns / 1 ns
`define PERIOD 100

module cpu_top;
  reg rst,clk;
  integer test;
  
  reg[(3*8):0] mnemonic;
  wire[7:0] data;
  reg[12:0] PC_adr, IR_adr;
  
  wire[2:0] opcode;
  wire[12:0] addr,pc_addr,ir_addr;
  wire rd, wr, halt, ram_sel, rom_sel;
  
  cpu t_cpu(
            .clk(clk), 
            .rst(rst), 
            .rd(rd), 
            .wr(wr), 
            .halt(halt),
            .fetch(fetch),
            .opcode(opcode),
            .ir_addr(ir_addr),
            .pc_addr(pc_addr),
            .data(data),
            .addr(addr)
            );
            
  ram t_ram(
              .addr(addr[9:0]),
              .rd(rd),
              .wr(wr),
              .ena(ram_sel),
              .data(data));
              
  rom t_rom(
              .addr(addr),
              .rd(rd),
              .ena(rom_sel),
              .data(data));
              
  addr_decode t_addr_decode(
              .addr(addr),
              .ram_sel(ram_sel),
              .rom_sel(rom_sel));
                     
                     
initial
  begin
    clk = 1;
    $timeformat(-9, 1, "ns", 12);
    display_debug_message;
    sys_reset;
   // test1;
   // $stop;
   // test2;
   // $stop;
    test3;
    $finish;
  end
  
  task display_debug_message;
    begin
      $display ("\n***************************************");
      $display ("* \"test1;\"to load the 1st diagnostic progran. *");
      $display ("* \"test2;\"to load the 2nd diagnostic progran. *");
      $display ("* \"test3;\"to load the Fibonacci diagnostic progran. *");
    end
  endtask
  
  task test1;
    begin
     test = 0;
     disable MONITOR;
     $readmemb("test1.pro", t_rom.memory);
     $display("rom loaded successfully");
     $readmemb("test1.dat", t_ram.ram);
     $display("ram loaded successfully");
     #1 test = 1;
     #14800;
      sys_reset;
    end
  endtask
  
  task test2;
    begin
     test = 0;
     disable MONITOR;
     $readmemb("test2.pro", t_rom.memory);
     $display("rom loaded successfully");
     $readmemb("test2.dat", t_ram.ram);
     $display("ram loaded successfully");
     #1 test = 2;
     #11600;
      sys_reset;
    end
  endtask
  
  task test3;
    begin
     test = 0;
     disable MONITOR;
     $readmemb("test3.pro", t_rom.memory);
     $display("rom loaded successfully");
     $readmemb("test3.dat", t_ram.ram);
     $display("ram loaded successfully");
     #1 test = 3;
     #94000;
      sys_reset;
    end
  endtask
  
  task sys_reset;
    begin
      rst = 0;
      #(`PERIOD * 0.7 ) rst = 1;
      #(1.5 * `PERIOD ) rst = 0;
    end
  endtask
  
  always@(test)
  begin: MONITOR
    case(test)
      1:begin
        $display("\n***RUNNING CPUtest1 - The Basic CPU Diagnostic Program ***");
        $display("\nTIME   PC   INSTR    ADDR    DATA  ");
        $display("---------   ---  ------   ----    ------");
        while( test == 1)
          @(t_cpu.m_adr.pc_addr)
          if((t_cpu.m_adr.pc_addr%2 == 1) && (t_cpu.m_adr.fetch == 1))
            begin
              #60 PC_adr <= t_cpu.m_adr.pc_addr - 1;
                  IR_adr <= t_cpu.m_adr.ir_addr;
              #340 $strobe("%t   %h    %s    %h    %h", $time, PC_adr, mnemonic, IR_adr, data);
            end
          end
          
        2:begin
          $display("\n***RUNNING CPUtest2-The Advanced CPUDiagnostic Program ***");
          $display("\nTIME     PC     INSTR     ADDR      DATA    ");
          $display("--------   --     -----     ----      ----    ");
          while(test == 2)
            @(t_cpu.m_adr.pc_addr)
            if((t_cpu.m_adr.pc_addr%2 == 1) && (t_cpu.m_adr.fetch == 1))
              begin
                #60 PC_adr <= t_cpu.m_adr.pc_addr - 1;
                    IR_adr <= t_cpu.m_adr.ir_addr;
                #340 $strobe("%t  %h  %s  %h %h", $time, PC_adr, mnemonic, IR_adr, data);
              end
            end
            
        3:begin
          $display("\n***RUNNING CPUtest3-An Executable Program ***");
          $display("*** The program should calculate the fibonacci ***");
          $display("    ------  ----  ----  ----  ----  ------");
          while(test == 3)
            begin
              wait( t_cpu.m_alu.opcode == 3'h1 );
              $strobe("%t   %d", $time, t_ram.ram[10'h2]);
              wait( t_cpu.m_alu.opcode != 3'h1 );
            end
          end
        endcase
      end
      
      always@(posedge halt)
      begin
        #500
          $display("\n****************************************");
          $display("** A HALT INSTRUCTION WAS PROCESSED !!! **");
          $display("****************************************\n");
      end

      always #(`PERIOD/2) clk = !clk;
      always @(t_cpu.opcode)
        case(t_cpu.m_alu.opcode)
          3'b000: mnemonic = "HLT";
          3'h1  : mnemonic = "SKZ";
          3'h2  : mnemonic = "ADD";
          3'h3  : mnemonic = "AND";
          3'h4  : mnemonic = "XOR";
          3'h5  : mnemonic = "LDA";
          3'h6  : mnemonic = "STO";
          3'h7  : mnemonic = "JMP";
          default: mnemonic = "???";
        endcase
        
endmodule