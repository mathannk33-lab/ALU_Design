module Eight_bit_ALU_rtl_design #(parameter WIDTH = 4)
(
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

reg check;
reg [WIDTH-1:0] OPA_1, OPB_1, OPA_NEW, OPB_NEW;
reg signed [WIDTH-1:0] SIGOPA, SIGOPB, SIGOUT;

always @(posedge CLK or posedge RST)
begin
    if (RST)
    begin
        RES <= 'b0;
        COUT <= 1'b0;
        OFLOW <= 1'b0;
        G <= 1'b0;
        E <= 1'b0;
        L <= 1'b0;
        ERR <= 1'b0;
    end
    else if (CE)
    begin
        if (MODE)
        begin
            RES <= 'b0;
            COUT <= 1'b0;
            OFLOW <= 1'b0;
            G <= 1'b0;
            E <= 1'b0;
            L <= 1'b0;
            ERR <= 1'b0;

            if (check)
            begin
                case (CMD)

                    4'b0000:
                    begin
                        RES <= OPA + OPB;
                        COUT <= RES[WIDTH] ? 1 : 0;
                    end

                    4'b0001:
                    begin
                        RES <= OPA - OPB;
                        OFLOW <= (OPA < OPB) ? 1 : 0;
                    end

                    4'b0010:
                    begin
                        RES <= OPA + OPB + CIN;
                        COUT <= RES[WIDTH] ? 1 : 0;
                    end

                    4'b0011:
                    begin
                        OFLOW <= (OPA < OPB || OPA < (OPB + CIN)) ? 1 : 0;
                        RES <= OPA - OPB - CIN;
                    end

                    4'b0100:
                    begin
                        RES <= OPA + 1;
                    end

                    4'b0101:
                    begin
                        RES <= OPA - 1;
                    end

                    4'b0110:
                    begin
                        RES <= OPB + 1;
                    end

                    4'b0111:
                    begin
                        RES <= OPB - 1;
                    end

                    4'b1000:
                    begin
                        RES <= 'b0;
                        if (OPA == OPB)
                        begin
                            E <= 1'b1;
                            G <= 1'b0;
                            L <= 1'b0;
                        end
                        else if (OPA > OPB)
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
                        if (OPA_NEW != 'bx && OPB_NEW != 'bx)
                        begin
                            RES <= OPA_NEW * OPB_NEW;
                            OPA_NEW <= 'bx;
                            OPB_NEW <= 'bx;
                        end
                        else
                        begin
                            OPA_NEW <= OPA + 1;
                            OPB_NEW <= OPB + 1;
                            RES <= 'bx;
                        end
                    end

                    4'b1010:
                    begin
                        if (OPA_NEW != 'bx && OPB_NEW != 'bx)
                        begin
                            RES <= OPA_NEW * OPB_NEW;
                            OPA_NEW <= 'bx;
                            OPB_NEW <= 'bx;
                        end
                        else
                        begin
                            OPA_NEW <= OPA << 1;
                            OPB_NEW <= OPB;
                            RES <= 'bx;
                        end
                    end

                    4'b1011:
                    begin
                        RES <= SIGOUT;
                        if ((OPA[WIDTH-1] == OPB[WIDTH-1]) &&
                            OPA[WIDTH-1] != SIGOUT[WIDTH-1])
                            OFLOW <= 1;
                        else
                            OFLOW <= 0;
                    end

                    4'b1100:
                    begin
                        RES <= SIGOUT;
                        if ((OPA[WIDTH-1] != OPB[WIDTH-1]) &&
                            OPA[WIDTH-1] != SIGOUT[WIDTH-1])
                            OFLOW <= 1;
                        else
                            OFLOW <= 0;
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
                ERR <= 1'b1;
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

            if (check)
            begin
                case (CMD)

                    4'b0000: RES <= {1'b0, OPA & OPB};
                    4'b0001: RES <= {1'b0, ~(OPA & OPB)};
                    4'b0010: RES <= {1'b0, OPA | OPB};
                    4'b0011: RES <= {1'b0, ~(OPA | OPB)};
                    4'b0100: RES <= {1'b0, OPA ^ OPB};
                    4'b0101: RES <= {1'b0, ~(OPA ^ OPB)};
                    4'b0110: RES <= {1'b0, ~OPA};
                    4'b0111: RES <= {1'b0, ~OPB};
                    4'b1000: RES <= {1'b0, OPA >> 1};
                    4'b1001: RES <= {1'b0, OPA << 1};
                    4'b1010: RES <= {1'b0, OPB >> 1};
                    4'b1011: RES <= {1'b0, OPB << 1};

                    4'b1100:
                    begin
                        if (OPB[WIDTH-1:$clog2(WIDTH)+1] == 'b0)
                            RES <= OPA_1;
                        else
                        begin
                            RES <= 'b0;
                            ERR <= 1;
                        end
                    end

                    4'b1101:
                    begin
                        if (OPB[WIDTH-1:$clog2(WIDTH)+1] == 'b0)
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
                ERR <= 1'b1;
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
    end
end

always @(*)
begin
    if (MODE)
    begin
        case (CMD)
            4'b0,4'b01,4'b10,4'b11,4'b1000,4'b1001,4'b1010,4'b1011,4'b1100:
                check = (INP_VAD == 3) ? 1 : 0;
            4'b100,4'b101:
                check = (INP_VAD == 3 || INP_VAD == 1) ? 1 : 0;
            4'b110,4'b111:
                check = (INP_VAD == 3 || INP_VAD == 2) ? 1 : 0;
        endcase

        SIGOPA = OPA;
        SIGOPB = OPB;

        SIGOUT = (CMD == 4'b1011) ? (SIGOPA + SIGOPB) :
                 (CMD == 4'b1100) ? (SIGOPA - SIGOPB) : 4'b0;
    end
    else
    begin
        case (CMD)
            4'b0,4'b1,4'b10,4'b11,4'b100,4'b101,4'b1100,4'b1101:
                check = (INP_VAD == 3) ? 1 : 0;
            4'b110,4'b1000,4'b1001:
                check = (INP_VAD == 3 || INP_VAD == 1) ? 1 : 0;
            4'b111,4'b1010,4'b1011:
                check = (INP_VAD == 3 || INP_VAD == 2) ? 1 : 0;
        endcase

        OPB_1 = OPB[($clog2(WIDTH)-1):0] % WIDTH;

        if (CMD == 4'b1100)
        begin
            if (OPB_1 != 0)
                OPA_1 = (OPA << OPB_1) | (OPA >> (WIDTH - OPB_1));       
	    else
                OPA_1 = OPB_1;
        end
        else if (CMD == 4'b1101)
        begin
            if (OPB_1 != 0)
                OPA_1 = (OPA >> OPB_1) | (OPA << (WIDTH - OPB_1));
            else
                OPA_1 = OPB_1;
        end
    end
end

endmodule
