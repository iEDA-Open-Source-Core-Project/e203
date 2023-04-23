module preDebug(
  // input [2:0] exeBranch,
  input dec_rv32_beq, 
  input dec_rv32_bne,
  input dec_rv32_blt,
  input dec_rv32_bgt,
  input dec_rv32_bltu,
  input dec_rv32_bgtu,
  input dec_rv16_beqz,
  input dec_rv16_bnez,


  //TODO: 预测失败后指令信息
  input takenMiss,
  input [4:0] rs1Addr,
  //TODO： 查看如何e203以那条指令结束
  input coreEnd
);

  reg [31:0] bjp [0:8];
  reg [31:0] bjpMiss [0:8];

  reg [31:0] jal;
  reg [31:0] jalr;
  reg [31:0] beq;
  reg [31:0] bne;
  reg [31:0] blt;
  reg [31:0] bltu;
  reg [31:0] bge;
  reg [31:0] bgtu;
  
  bjp[0]= dec_rv32_beq  ? bjp[0] + 1: bjp[0];
  bjp[1]= dec_rv32_bne & (rs1Addr != 5'd1) ? bjp[1] + 1: bjp[1];
  bjp[8]= dec_rv32_bne & (rs1Addr == 5'd1) ? bjp[8] + 1: bjp[8]; // ret
  bjp[2]= dec_rv32_blt  ? bjp[2] + 1: bjp[2];
  bjp[3]= dec_rv32_bgt  ? bjp[3] + 1: bjp[3];
  bjp[4]= dec_rv32_bltu ? bjp[4] + 1: bjp[4];
  bjp[5]= dec_rv32_bgtu ? bjp[5] + 1: bjp[5];
  bjp[6]= dec_rv32_beqz ? bjp[6] + 1: bjp[6];
  bjp[7]= dec_rv32_bnez ? bjp[7] + 1: bjp[7];


  bjpMiss[0]= dec_rv32_beq  ? bjpMiss[0] + 1: bjpMiss[0];
  bjpMiss[1]= dec_rv32_bne & (rs1Addr != 5'd1) ? bjpMiss[1] + 1: bjpMiss[1];
  bjpMiss[8]= dec_rv32_bne & (rs1Addr == 5'd1) ? bjpMiss[8] + 1: bjpMiss[8]; // ret

  bjpMiss[2]= dec_rv32_blt  ? bjpMiss[2] + 1: bjpMiss[2];
  bjpMiss[3]= dec_rv32_bgt  ? bjpMiss[3] + 1: bjpMiss[3];
  bjpMiss[4]= dec_rv32_bltu ? bjpMiss[4] + 1: bjpMiss[4];
  bjpMiss[5]= dec_rv32_bgtu ? bjpMiss[5] + 1: bjpMiss[5];
  bjpMiss[6]= dec_rv32_beqz ? bjpMiss[6] + 1: bjpMiss[6];
  bjpMiss[7]= dec_rv32_bnez ? bjpMiss[7] + 1: bjpMiss[7];

  // always @(*) begin
  //     case (exeBranch)
  //       3'b001: begin
  //         bjp[0] <= bjp[0] + 1;
  //         if (takenMiss) begin
  //           bjpMiss[0] <= bjpMiss[0] + 1;
  //         end
  //       end
  //       3'b010: begin
  //         if (rs1Addr == 5'd1) begin
  //           bjp[6] <= bjp[6] + 1;
  //           if (takenMiss) begin
  //             bjpMiss[6] <= bjpMiss[6] + 1;
  //           end
  //         end else begin
  //           bjp[1] <= bjp[1] + 1;
  //           if (takenMiss) begin
  //             bjpMiss[1] <= bjpMiss[1] + 1;
  //           end
  //         end
  //       end
  //       3'b100: begin
  //         bjp[2] <= bjp[2] + 1;
  //         if (takenMiss) begin
  //           bjpMiss[2] <= bjpMiss[2] + 1;
  //         end
  //       end
  //       3'b101: begin
  //         bjp[3] <= bjp[3] + 1;
  //         if (takenMiss) begin
  //           bjpMiss[3] <= bjpMiss[3] + 1;
  //         end
  //       end
  //       3'b110: begin
  //         bjp[4] <= bjp[4] + 1;
  //         if (takenMiss) begin
  //           bjpMiss[4] <= bjpMiss[4] + 1;
  //         end
  //       end
  //       3'b111: begin
  //         bjp[5] <= bjp[5] + 1;
  //         if (takenMiss) begin
  //           bjpMiss[5] <= bjpMiss[5] + 1;
  //         end
  //       end
  //     endcase
  // end

  always @(*) begin
    if (coreEnd) begin
      $display("Name:\tjal\t\tjalr\t\tret\t\tbeq\t\tbne\t\tblt\t\tbge");
      $display("ALL:\t%d\t%d\t%d\t%d\t%d\t%d\t%d", bjp[0], bjp[1], bjp[6], bjp[2], bjp[3], bjp[4], bjp[5]);
      $display("Miss:\t%d\t%d\t%d\t%d\t%d\t%d\t%d", bjpMiss[0], bjpMiss[1], bjpMiss[6], bjpMiss[2], bjpMiss[3], bjpMiss[4], bjpMiss[5]);
      jal  <= bjpMiss[0] / bjp[0];
      jalr <= bjpMiss[1] / bjp[1];
      beq  <= bjpMiss[2] / bjp[2];
      bne  <= bjpMiss[3] / bjp[3];
      blt  <= bjpMiss[4] / bjp[4];
      bge  <= bjpMiss[5] / bjp[5];
    end
  end

endmodule