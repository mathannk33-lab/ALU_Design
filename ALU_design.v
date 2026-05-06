`timescale 1ns / 1ps
module ALU_DESIGN_NEW #(parameter WIDTH = 4)(
    OPA, OPB, CIN, CLK, RST, CMD, CE, MODE, INP_VAD,
    COUT, OFLOW, RES, G, E, L, ERR
    );
input [WIDTH-1:0] OPA, OPB;
input CLK, RST, CE, MODE, CIN;
input [1:0] INP_VAD;
input [3:0] CMD;

output reg [2*WIDTH-1:0] RES = 'bz;
output reg COUT = 1'bz;
output reg OFLOW = 1'bz;
output reg G = 1'bz;
output reg E = 1'bz;
output reg L = 1'bz;
output reg ERR = 1'bz;

reg check,mul_state1=0,mul_state2=0;
reg [WIDTH:0]carry;
reg [WIDTH-1:0] OPA_NEW,OPB_NEW;
reg [WIDTH-1:0] OPA_1,OPB_1;
reg [WIDTH-1:0] OPA_MUL='bx,OPB_MUL='bx;
reg CIN_NEW,MODE_NEW;
reg [1:0]INP_VALID_NEW;
reg [3:0] CMD_NEW;
reg signed [WIDTH-1:0] SIGOPA, SIGOPB, SIGOUT;


always @(posedge CLK or posedge RST) 
    begin
        OPA_NEW<=OPA;
        OPB_NEW<=OPB;
        CIN_NEW<=CIN;
        MODE_NEW<=MODE;
        CMD_NEW<=CMD;
        INP_VALID_NEW<=INP_VAD;
        if (RST)
            begin
                RES <= 'b0;
                COUT <= 1'b0;
                OFLOW <= 1'b0;
                G <= 1'b0;
                E <= 1'b0;
                L <= 1'b0;
                ERR <= 1'b0;
                mul_state1<=1'b0;
                mul_state2<=1'b0;
                
            end
        else if(CE) 
            begin
                RES<='b0;
                COUT<=1'b0;
                OFLOW<=1'b0;
                G<=1'b0;
                E<=1'b0;
                L<=1'b0;
                ERR<=1'b0;
                
                if(MODE_NEW)
                    begin
                        if(check)
                            begin
                                case(CMD_NEW)
                                    4'b0000:
                                        begin
                                            RES <= OPA_NEW + OPB_NEW;
                                            COUT <=carry[WIDTH] ;
                                        end
                                    4'b0001:
                                        begin
                                            RES<= OPA_NEW - OPB_NEW;
                                            OFLOW <= (OPA_NEW < OPB_NEW) ? 1 : 0;
                                        end
                                    4'b0010:
                                        begin
                                            RES <= OPA_NEW + OPB_NEW + CIN_NEW;
                                            COUT <= RES[WIDTH] ? 1 : 0;
                                        end
                                    4'b0011:
                                        begin
                                            OFLOW <= (OPA_NEW < OPB_NEW || OPA_NEW < (OPB_NEW + CIN_NEW)) ? 1 : 0;
                                            RES <= OPA_NEW - OPB_NEW - CIN_NEW;
                                        end                               
                                    4'b0100:RES <= OPA_NEW + 1;        
                                    4'b0101:RES <= OPA_NEW - 1;
                                    4'b0110:RES <= OPB_NEW + 1;
                                    4'b0111:RES <= OPB_NEW - 1;
                                    4'b1000:
                                        begin
                                            RES <= 'b0;
                                            if (OPA_NEW == OPB_NEW)
                                                begin
                                                    E <= 1'b1;
                                                    G <= 1'b0;
                                                    L <= 1'b0;
                                                end
                                            else if (OPA_NEW > OPB_NEW)
                                                begin
                                                    E <= 1'b0;
                                                    G <= 1'b1;
                                                    L <= 1'b0;
                                                end
                                            else
                                                begin
                                                    E <= 1'b0;
                                                    G <= 1'b0;
                                                    L <= 1'b1;
                                                end
                                        end
                                    4'b1001:
                                        begin
                                            case(mul_state1)
                                                1'd0: 
                                                    begin
                                                        OPA_MUL <= OPA_NEW+1;
                                                        OPB_MUL <= OPB_NEW+1;
                                                        mul_state1 <= 1'd1;
                                                        RES <= 'bx;
                                                    end
                                                1'd1:
                                                    begin
                                                        RES <= OPA_MUL * OPB_MUL;
                                                        mul_state1<=1'b0;
                                                        OPA_MUL<=0;
                                                        OPB_MUL<=0;
                                                    end
                                            endcase
                                        end            
                                    4'b1010:
                                        begin
                                            case(mul_state2)
                                                1'd0: 
                                                    begin
                                                        OPA_MUL <= OPA_NEW<<1;
                                                        OPB_MUL <= OPB_NEW;
                                                        mul_state2 <= 2'd1;
                                                        RES <= 'bx;
                                                    end
                                                1'd1:
                                                    begin
                                                        RES <= OPA_MUL * OPB_MUL;
                                                        mul_state2<=1'b0;
                                                        OPA_MUL<=0;
                                                        OPB_MUL<=0;
                                                    end
                                            endcase
                                        end  
                                    4'b1011:
                                        begin
                                            RES <= SIGOUT;
                                            if ((OPA_NEW[WIDTH-1] == OPB_NEW[WIDTH-1]) && OPA_NEW[WIDTH-1] != SIGOUT[WIDTH-1])
                                                OFLOW <= 1;
                                            else
                                                OFLOW <= 0;
                                            if(SIGOPA > SIGOPB) G<=1;
                                            else if(SIGOPA == SIGOPB) E<=1;
                                            else L<=1;
                                        end
                                    4'b1100:
                                        begin
                                            RES <= SIGOUT;
                                            if ((OPA_NEW[WIDTH-1] != OPB_NEW[WIDTH-1]) && OPA_NEW[WIDTH-1] != SIGOUT[WIDTH-1])
                                                OFLOW <= 1;
                                            else
                                                OFLOW <= 0;
                                            if(SIGOPA > SIGOPB) G<=1;
                                            else if(SIGOPA == SIGOPB) E<=1;
                                            else L<=1;
                                        end
                                    default:
                                        begin
                                            RES <= 'b0;
                                            COUT <= 1'b0;
                                            OFLOW <= 1'b0;
                                            G <= 1'b0;
                                            E <= 1'b0;
                                            L <= 1'b0;
                                            ERR <= 1'b0;
                                        end
                                endcase
                            end
                        else 
                            begin
                                ERR<=1'b1;
                            end
                    end
                else
                    begin
                        if(check)
                            begin
                                case(CMD_NEW)
                                    4'b0000:RES <= {1'b0, OPA_NEW & OPB_NEW};
                                    4'b0001:RES <= {1'b0, ~(OPA_NEW & OPB_NEW)};
                                    4'b0010:RES <= {1'b0, OPA_NEW | OPB_NEW};
                                    4'b0011:RES <= {1'b0, ~(OPA_NEW | OPB_NEW)};
                                    4'b0100:RES <= {1'b0, OPA_NEW ^ OPB_NEW};
                                    4'b0101:RES <= {1'b0, ~(OPA_NEW ^ OPB_NEW)};
                                    4'b0110:RES <= {1'b0, ~OPA_NEW};
                                    4'b0111:RES <= {1'b0, ~OPB_NEW};
                                    4'b1000:RES <= {1'b0, OPA_NEW >> 1};
                                    4'b1001:RES <= {1'b0, OPA_NEW << 1};
                                    4'b1010:RES <= {1'b0, OPB_NEW >> 1};
                                    4'b1011:RES <= {1'b0, OPB_NEW << 1};
                                    4'b1100:
                                        begin
                                            if (OPB_NEW[WIDTH-1:$clog2(WIDTH)+1] == 'b0)
                                                RES <= OPA_1;
                                            else
                                                begin
                                                    RES <= 'b0;
                                                    ERR <= 1;
                                                end
                                        end
                                    4'b1101:
                                        begin
                                            if (OPB_NEW[WIDTH-1:$clog2(WIDTH)+1] == 'b0)
                                                RES <= OPA_1;
                                            else
                                                begin
                                                    RES <= 'b0;
                                                    ERR <= 1;
                                                end
                                        end
                                    default:
                                        begin
                                            RES <= 'b0;
                                            COUT <= 1'b0;
                                            OFLOW <= 1'b0;
                                            G <= 1'b0;
                                            E <= 1'b0;
                                            L <= 1'b0;
                                            ERR <= 1'b0;
                                        end
                                endcase
                            end
                        else 
                            begin
                                ERR<=1'b1;
                            end     
                    end
            end  
        else 
            begin
                RES <= 'b0;
                COUT <= 1'b0;
                OFLOW <= 1'b0;
                G <= 1'b0;
                E <= 1'b0;
                L <= 1'b0;
                ERR <= 1'b0;
            end
    end
    
    always @(*)
        begin
                if (MODE_NEW)
                    begin
                        case (CMD_NEW)
                            4'b0,4'b01,4'b10,4'b11,4'b1000,4'b1001,4'b1010,4'b1011,4'b1100:check = (INP_VALID_NEW == 3) ? 1 : 0;
                            4'b100,4'b101:check = (INP_VALID_NEW == 3 || INP_VALID_NEW == 1) ? 1 : 0;
                            4'b110,4'b111:check = (INP_VALID_NEW == 3 || INP_VALID_NEW == 2) ? 1 : 0;
                        endcase
                        if(CMD==4'b1001 || CMD==4'b1010)begin
                        if(CMD!=CMD_NEW)begin
                            mul_state1=0;
                            mul_state2=0;
                            end
                         end
                         
                         else if(CMD_NEW == 4'B1001 || CMD_NEW==4'B1010)begin
                            if(CMD!=CMD_NEW) begin
                                mul_state1=1;
                                mul_state2=1;
                            end
                         end
                        carry=(CMD_NEW==4'b0)?(OPA_NEW+OPA_NEW):0;
                        SIGOPA = OPA_NEW;
                        SIGOPB = OPB_NEW;
                        SIGOUT = (CMD_NEW == 4'b1011) ? (SIGOPA + SIGOPB) :(CMD_NEW == 4'b1100) ? (SIGOPA - SIGOPB) : 4'b0;
                    end
                else
                    begin
                        case (CMD_NEW)
                            4'b0,4'b1,4'b10,4'b11,4'b100,4'b101,4'b1100,4'b1101:check = (INP_VALID_NEW == 3) ? 1 : 0;
                            4'b110,4'b1000,4'b1001:check = (INP_VALID_NEW == 3 || INP_VALID_NEW == 1) ? 1 : 0;
                            4'b111,4'b1010,4'b1011:check = (INP_VALID_NEW == 3 || INP_VALID_NEW == 2) ? 1 : 0;
                        endcase
                        OPB_1 = OPB_NEW[($clog2(WIDTH)-1):0] % WIDTH;
                        if (CMD_NEW == 4'b1100)
                            begin
                                if (OPB_1 != 0)
                                    OPA_1 = (OPA_NEW << OPB_1) | (OPA_NEW >> (WIDTH - OPB_1));       
	                            else
                                OPA_1 = OPB_1;
                            end
                        else if (CMD_NEW == 4'b1101)
                            begin
                                if (OPB_1 != 0)
                                    OPA_1 = (OPA_NEW >> OPB_1) | (OPA_NEW << (WIDTH - OPB_1));
                                else
                                    OPA_1 = OPB_1;
                            end
                    end
        end
                             
endmodule

