/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : divider_trim.sv
 * @created     : Thursday Dec 08, 2022 12:42:28 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        08/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------


`include "./fv/includes/rnm_include.sv"

module divider_trim(vin, en, trim, vout1, vout2);
    input vin, en;
    input[4:0] trim;
    output vout1, vout2;
    `REAL_NET vin, vout1, vout2;
    wire en;
    wire[4:0] trim;
    parameter real rtop = 331.767e3;
    parameter real rbot = 35.2502e3;
    parameter real rout1 = 165.883e3;
    parameter real rout2 = rout1;
    parameter real rtrim_base = 2.07354e3;
    parameter real off_value = 0;

    real rtrim, rbottom, rbot_total;
    always_comb begin
        rtrim = rtrim_base * (1 + trim[4]) / 2.0;
        rtrim += rtrim_base * (1 - trim[3] / 4.0);
        rtrim += rtrim_base / 2.0 * (1 - trim[2] / 4.0);
        rtrim += rtrim_base / 2.0 * (1 - trim[1] / 8.0);
        rtrim += rtrim_base / 2.0 * (1 - trim[0] / 16.0);
    end
    assign rbottom = rbot + rtrim;
    assign rbot_total = 1 / (1 / rbottom + 1 / (rout2 + rout1));
    assign vout1 = en ? rbot_total / (rtop + rbot_total) * vin : off_value;
    assign vout2 = en ? vout1 * rout2 / (rout2 + rout1) : off_value;

endmodule //divider_trim

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_comp.sv
 * @created     : Tuesday Dec 06, 2022 01:15:30 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        06/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------



`include "./fv/includes/rnm_include.sv"
module nvt_sv_comp(p, n, en, out);
    inout p, n;
    input en;
    wire en;
    output out;
    wire out;
    `REAL_NET p, n;
    parameter real offset  = 0.0;   // offset value
    parameter real hyst  = 0.0;   // hysteresis of the comparator
    parameter dis_val = 0;  // default output when comparator is disabled
    parameter hyst_dir = 0; //direction of the hysteresis - 0 rising, 1 falling
    parameter real tr = 85e-9;
    parameter real tf = 85e-9;

    reg out_reg = 1'b0;
    wire temp_out;
    assign temp_out = en ? out_reg : dis_val;
    buf #(tr * 1e9, tf * 1e9) buf_out(out, temp_out);
    always_comb begin
        if(((p - n) - offset - (1 - hyst_dir) * hyst) > 0) out_reg = 1'b1;
        else if(((n - p) + offset - hyst_dir * hyst) >= 0) out_reg = 1'b0;
    end

endmodule //nvt_sv_comp

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_comp_hyst_2n.sv
 * @created     : Friday Dec 09, 2022 01:19:01 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        09/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------

`include "./fv/includes/rnm_include.sv"
module nvt_sv_comp_hyst_2n(p, n1, n2, en, out);
    inout p, n1, n2;
    input en;
    wire en;
    output out;
    wire out;
    `REAL_NET p, n1, n2, n;
    parameter real offset  = 0.0;   // offset value
    parameter dis_val = 0;  // default output when comparator is disabled
    parameter real tr = 85e-9;
    parameter real tf = 85e-9;

    //reg out_reg = 1'b0;
    wire temp_out;
    assign n = out ? n2 : n1;
    assign temp_out = en ? (p - n - offset > 0) : dis_val;
    buf #(tr * 1e9, tf * 1e9) buf_out(out, temp_out);

endmodule //nvt_sv_comp_hyst_2n
/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_comp_hyst_2p.sv
 * @created     : Friday Dec 09, 2022 02:41:23 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        09/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------


`include "./fv/includes/rnm_include.sv"
module nvt_sv_comp_hyst_2p(p1, p2, n, en, out);
    inout n, p1, p2;
    input en;
    wire en;
    output out;
    wire out;
    `REAL_NET p, p1, p2, n;
    parameter real offset  = 0.0;   // offset value
    parameter dis_val = 0;  // default output when comparator is disabled
    parameter real tr = 85e-9;
    parameter real tf = 85e-9;

    wire temp_out;
    //assign p = temp_out ? p1 : p2;
    assign p = out ? p1 : p2;
    assign temp_out = en ? (p - n - offset > 0) : dis_val;
    buf #(tr * 1e9, tf * 1e9) buf_out(out, temp_out);

endmodule //nvt_sv_comp_hyst_2p
/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_ichk.sv
 * @created     : Thursday Dec 01, 2022 04:11:03 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//        current check is to remove the exp_val from input and compare with exp_val * accuracy, if there are multiple connecting
//        then it will be no good (only valid for wrealsum)
//
//        History:
//        Date          Rev         who          Comments
//        01/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------


`include "./fv/includes/rnm_include.sv"
module nvt_sv_ichk(in, out);
    input in;   `REAL_NET in;
    output out;   wire out;
    parameter real exp_val = 1e-6;
    parameter real accuracy = 0.1; //10%
    `REAL_NET exp_min, exp_max, abs_val, curr_in;
    assign abs_val = exp_val > 0 ? exp_val : -exp_val;
    assign exp_min = abs_val < 1e-9 ? -accuracy : -abs_val * accuracy;
    assign exp_max = abs_val < 1e-9 ? accuracy : abs_val * accuracy;
    assign in = abs_val * accuracy;
    assign curr_in = in - exp_val - abs_val * accuracy;
    `ifndef NO_BIAS_CHECK
        assign out = curr_in >= exp_min && curr_in <= exp_max;
    `else
        assign out = 1'b1;
    `endif
endmodule //nvt_ichk

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_mux.sv
 * @created     : Friday Dec 09, 2022 04:30:01 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        09/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------



`include "./fv/includes/rnm_include.sv"
module nvt_sv_mux(in, sel, en, out);
    parameter NUM_BITS = 3;
    localparam NUM_IN = 1 << NUM_BITS;
    input [NUM_IN - 1 : 0] in;
    input [NUM_BITS - 1 : 0] sel;
    input en;
    output out;
    `REAL_NET in[NUM_IN - 1 : 0];
    `REAL_NET out;
    real out_val;
    always_comb begin
        out_val = in[sel];
    end
    assign out = en ? out_val : `wrealZState;

endmodule //nvt_sv_mux

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_osci.sv
 * @created     : Wed Jan 11 03:30:46 2023 by xwzhang
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//        A generic oscillator model
//
//
//        History:
//        Date          Rev         who          Comments
//        11/01/2023     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------



module nvt_sv_osci(en, out);
    input en;
    output out;
    wire en, out;
    parameter real def_freq = 1e6;
    parameter real def_duty = 0.5;
    real freq;
    real period;
    real duty;
    reg change = 1'b0;
    reg clk_out = 1'b0;
    initial begin
        freq = def_freq;
        period = 1.0 / freq;
        duty = def_duty;
    end

    assign out = clk_out;

    always @(posedge en) begin
        disable DIS_CLK;
        forever begin : CLK
            clk_out = 1'b0;
            #((1 - duty) * period * 1e9) clk_out = 1'b1;
            #(duty * period * 1e9) clk_out = 1'b0;
        end
    end

    always @(negedge en) begin : DIS_CLK
        if(clk_out) wait(clk_out === 1'b0);
        disable CLK;
        #((1 - duty) * period * 1e9) clk_out = 1'b0;
    end

    task set_freq;
    input real in_val;
    begin
        freq = in_val;
        period = 1 / freq;
        change = ~change;
    end
    endtask

    task set_duty;
    input real in_val;
    begin
        duty = in_val;
        change = ~change;
    end
    endtask

endmodule //nvt_sv_osci

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_src.sv
 * @created     : Thursday Dec 01, 2022 04:58:39 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        01/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------


`include "./fv/includes/rnm_include.sv"
module nvt_sv_src(out, en);
    input en;     wire en;
    output out;   `REAL_NET out;
    parameter real dc  = 0.0;   // V set
    parameter real tr = 100e-9; //default rise time for voltage source
    parameter real tf = 100e-9; //default fall time for voltage source
    //parameter integer nstep = 10 from [1:100]; //default number of steps change
    parameter integer nstep = 10; //default number of steps change
    real src_val = dc;
    real trise = tr;
    real tfall = tf;
    integer step_cnt = nstep;
    assign out = en === 1'b1 ? src_val : `wrealZState;

    task ramp_src_val;
    input real in_val;
    input real ramp_time;
    real orig_v, dv, tdelay;
    begin
        trise = ramp_time / step_cnt;
        tfall = ramp_time / step_cnt;
        orig_v = src_val;
        dv = (in_val - orig_v) / step_cnt;
        if(dv > 0) tdelay = trise;
        else tdelay = tfall;
        repeat(step_cnt) begin
            #(tdelay * 1e9);
            src_val = src_val + dv;
        end
    end
    endtask

    task set_src_val;
    input real in_val;
    real orig_v, dv, tdelay;
    begin
        orig_v = src_val;
        dv = (in_val - orig_v) / step_cnt;
        if(dv > 0) tdelay = tr;
        else tdelay = tf;
        ramp_src_val(in_val, tdelay);
    end
    endtask

    task set_steps;
    input integer in_val;
    begin
        if(in_val >= 1 && in_val <= 1000) begin
            step_cnt = in_val;
        end
    end
    endtask

endmodule //nvt_sv_src

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_swth.sv
 * @created     : Wednesday Dec 28, 2022 03:11:53 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        28/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------



`include "./fv/includes/rnm_include.sv"
module nvt_sv_swth(p, n, en);
    inout p, n;
    input en; wire en;
    `REAL_NET p, n;
    `REAL_NET p_ord, n_ord;
    parameter real delay = 1;
    real Zval, Xval;

    initial begin
        Zval = `wrealZState;
        Xval = `wrealXState;
        $SIE_input(p, p_ord);
        $SIE_input(n, n_ord);
    end
    assign #(delay) p = (en !== 1'b1)? Zval : n_ord;
    assign #(delay) n = (en !== 1'b1)? Zval : p_ord;
endmodule //nvt_sv_swth

/**
 * @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 * @file        : nvt_sv_vchk.sv
 * @created     : Thursday Dec 01, 2022 04:52:54 CST
 */
//
//        NuVolta Technologies, Inc.
//        Confidential Information
//
//        Description:
//
//
//
//        History:
//        Date          Rev         who          Comments
//        01/12/2022     1.0         xwzhang     Initial release
//
//----------------------------------------------------------------------------------------


module nvt_sv_vchk(in, out);
    input in;   `REAL_NET in;
    output out;   wire out;
    parameter real exp_val = 1.0;
    parameter real accuracy = 0.1; //10%
    `REAL_NET exp_min, exp_max, abs_val;
    assign abs_val = exp_val > 0 ? exp_val : -exp_val;
    assign exp_min = exp_val - abs_val * accuracy;
    assign exp_max = exp_val + abs_val * accuracy;
    `ifndef NO_BIAS_CHECK
        assign out = in >= exp_min && in <= exp_max;
    `else
        assign out = 1'b1;
    `endif
endmodule //nvt_ichk
