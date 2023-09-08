module SET (rst,clk,en,central,radius,mode,busy,valid,candidate);
    input   rst;
    input   clk;
    input   en;
    input   [23:0]central;
    input   [11:0]radius;
    input   [1:0]mode;

    output    busy;
    output    valid;
    output   [7:0]candidate;

    reg valid_d1;
    wire read_done;
    reg en_d1;
    wire cal_done;
    

    reg [8:0]ANS;
    wire [8:0]site;
    reg [2:0]circle;

    wire[3:0] ax,ay,bx,by,cx,cy,ar,br,cr;

    reg [1:0]counter_pic;

    reg [3:0]counter_x;
    reg [3:0]counter_y;

    reg [2:0]next_state;
    reg [2:0]cur_state;
    
    parameter IDLE=4'd0,READ=4'd1,CALCULATE=4'd2,ADDPIC=4'd3,CALANS=4'd4,ADDSITE=4'd5,OUTPUT=4'd6;
//===============================================
always @(posedge clk or posedge rst) begin
    if(rst)
        cur_state<=IDLE;
    else
        cur_state<=next_state;
end
always @(posedge clk) begin
    en_d1<=en;
end

assign read_done=((~en)&&(en_d1));

always @(*) begin
    case (cur_state)
        IDLE:begin
                next_state=READ;
        end
        READ:begin
            if(read_done)//read_done
                next_state=CALCULATE;
            else
                next_state=READ;
        end
        CALCULATE:begin
            next_state=ADDPIC;
        end
        ADDPIC:begin
            if(counter_pic==2)
                next_state=CALANS;
            else
                next_state=CALCULATE;
        end
        CALANS:begin
            next_state=ADDSITE;
        end
        ADDSITE:begin
            if(cal_done)
                next_state=OUTPUT;
            else
                next_state=CALCULATE;
        end
        OUTPUT:begin
                next_state=READ;
        end
        default: next_state=IDLE;
    endcase

end

assign ax=central[23:20];
assign ay=central[19:16];
assign bx=central[15:12];
assign by=central[11:8];
assign cx=central[7:4];
assign cy=central[3:0];

assign ar=radius[11:8];
assign br=radius[7:4];
assign cr=radius[3:0];

assign busy=(~((cur_state==IDLE)||(cur_state==READ)));
assign valid=(cur_state==OUTPUT);
assign candidate=(cur_state==OUTPUT)?ANS:8'd0;
assign cal_done=((counter_y==8)&&(counter_x==8));


//ANS
always @(posedge clk) begin     
    case (cur_state)
        READ:ANS=0;
        CALANS:begin
            case(mode)
                0:begin
                    ANS=ANS+circle[0];
                end
                1:begin
                    ANS=ANS+(circle[0]&circle[1]);
                end
                2:begin
                    ANS=ANS+(circle[0]^circle[1]);
                end
                3:begin
                    ANS=ANS+((circle[0]&circle[1])+(circle[0]&circle[2])+(circle[2]&circle[1])-3*(circle[2]&(circle[0]&circle[1])));
                end
            endcase
        end
    endcase
end

//counter_pic
always @(posedge clk or posedge rst) begin
    if(rst)
        counter_pic<=0;
    else if (cur_state==ADDPIC)begin
        if(counter_pic==2)
            counter_pic<=0;
        else    
            counter_pic<=counter_pic+1;
        end
end

//site
assign site=counter_x+counter_y*8;

//circle
 always @(posedge clk) begin
     if(cur_state==CALCULATE)begin
         case(counter_pic)
         0:circle[0]=dot_compare(counter_x,counter_y,ar,ax,ay);
		 1:circle[1]=dot_compare(counter_x,counter_y,br,bx,by);
		 2:circle[2]=dot_compare(counter_x,counter_y,cr,cx,cy);
         default:circle=circle;
        endcase
     end
     else begin
         circle=circle;
     end
 end

//counter_x 
always @(posedge clk) begin
    if (cur_state==READ) counter_x<=1;
        else if((counter_x==8)&&(cur_state==ADDSITE))
                    counter_x<=1;
                else if(cur_state==ADDSITE)
                    counter_x<=counter_x+1;
end


//counter_y
always @(posedge clk) begin
    if(cur_state==READ)
        counter_y<=1;
    else if((counter_x==8)&&(cur_state==ADDSITE))
        counter_y<=counter_y+1;
end

function dot_compare;
    input [3:0] X,Y,radius ;
    input [3:0] central_x,central_y;

    reg  [4:0] XD,YD;
    reg  [9:0] squ_x,squ_y;
    reg [9:0] squ_r;
    begin
        XD=(central_x>X)?(central_x-X):(X-central_x);
        YD=(central_y>Y)?(central_y-Y):(Y-central_y);
        squ_x=XD*XD;
        squ_y=YD*YD;
        squ_r=radius*radius;
        dot_compare=(squ_r>=(squ_x+squ_y));
    end
endfunction
//================================================
endmodule
