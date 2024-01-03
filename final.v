module final_project(
    output reg[7:0] LedR, LedG, LedB,
    output reg[2:0] comm,
    output reg enable,
    output reg[7:0] point,
	 output reg a,b,c,d,e,f,g,
    input SYS_CLK, RST, PAUSE, UP, DOWN, LEFT, RIGHT
	 
);

    // State machine states
    reg [1:0] state; // 01 is gaming, 10 is end

    // Clock signals
    reg game_clk;
    reg led_clk;

    // LED map 8*8
    reg [7:0] map [7:0]; // map[x][~y]

    // Snake position and body memory
    reg [2:0] X, Y; // snake head position
    reg [2:0] body_mem_x[63:0]; // position of X * 64
    reg [2:0] body_mem_y[63:0]; // position of Y * 64
    reg [5:0] length; // includes head

    // Item position
    reg [2:0] item_x, item_y;

    // Passed game flag
    reg pass;

    // Passed game picture
  

    // Counters and direction
    reg [6:0] i;
    reg [5:0] j;
    reg [24:0] led_counter;
    reg [24:0] move_counter;
    reg [1:0] move_dir;

    // Counter limits
    integer led_count_to = 5000; // led_clk 1 kHz display
    integer count_to = 4500000; // game_clk 0.5 Hz

    // Initial block
    initial begin
        // Initial LED values
        LedR = 8'b11111111;
        LedG = 8'b11111111;
        LedB = 8'b11111111;
        enable = 1'b1;
        comm = 3'b000;

        // Initialize passed game flag
        pass = 1'b0;

        

        // Initialize snake and item positions
        map[3'b010][~3'b010] = 1'b1; // head
        map[3'b001][~3'b010] = 1'b1; // body
        map[3'b000][~3'b010] = 1'b1; // body

        item_x = 3'b110;
        item_y = 3'b110;

        point = 8'b00000000;

        X = 3'b010;
        Y = 3'b010;

        body_mem_x[0] = 3'b010;
        body_mem_y[0] = 3'b010;
        body_mem_x[1] = 3'b010;
        body_mem_y[1] = 3'b001;
        body_mem_x[2] = 3'b010;
        body_mem_y[2] = 3'b000;
        length = 3;

        state = 2'b01;
        move_dir = 2'b00;
    end

    // Clock conversion and game_clk
    always @(posedge SYS_CLK) begin
        if (PAUSE == 1'b1) ; // Do nothing if paused
        else if (move_counter < count_to) move_counter <= move_counter + 1;
        else begin
            game_clk <= ~game_clk;
            move_counter <= 25'b0;
        end

        // led_clk
        if (led_counter < led_count_to) led_counter <= led_counter + 1;
        else begin
            led_counter <= 25'b0;
            led_clk <= ~led_clk;
        end
    end

    // LED display
    always @(posedge led_clk) begin
        if (comm == 3'b111) comm <= 3'b000;
        else comm <= comm + 1'b1;
    end

    // Update LED map and display item
    always @(comm) begin
       if (state == 2'b10)
		 begin
		 LedG = ~map[comm];
		 end
      else
		 begin 
		  LedG = ~map[comm];

		 end
        if (comm == item_x) LedR[item_y] = 1'b0;
        else LedR = 8'b11111111;
    end

    // Update snake direction
    always @(UP or DOWN or LEFT or RIGHT) begin
        if (UP == 1'b1 && DOWN != 1'b1 && LEFT != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b01)
            move_dir = 2'b00;
        else if (DOWN == 1'b1 && UP != 1'b1 && LEFT != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b00)
            move_dir = 2'b01;
        else if (LEFT == 1'b1 && UP != 1'b1 && DOWN != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b11)
            move_dir = 2'b10;
        else if (RIGHT == 1'b1 && UP != 1'b1 && DOWN != 1'b1 && LEFT != 1'b1 && move_dir != 2'b10)
            move_dir = 2'b11;
    end


  // Game logic
always @(posedge game_clk) begin
    if (move_dir == 2'b00) Y <= Y + 1;
    else if (move_dir == 2'b01) Y <= Y - 1;
    else if (move_dir == 2'b10) X <= X - 1;
    else if (move_dir == 2'b11) X <= X + 1;

    // Clear the tail of the snake
    map[body_mem_x[length - 1]][~body_mem_y[length - 1]] = 1'b0;

    // Move the body
    for (i = 1; i < length; i = i + 1)
	 begin
            body_mem_x[length - i] <= body_mem_x[length - i - 1];
            body_mem_y[length - i] <= body_mem_y[length - i - 1];
    end

    // Update the head
    body_mem_x[0] = X;
    body_mem_y[0] = Y;

    // Update the map with the new head position
    map[X][~Y] <= 1'b1;

    // Check for collisions
    if (point < 8'b00000001) state = 2'b01;

    // Check if the snake eats the item
    if (X == item_x && Y == item_y) begin
        if (point > 8'b11111110) state = 2'b10;
        point = point * 2 + 1'b1;
		  if(point > 8'b01111110)length = 7;
		  else if(point > 8'b00011110)length = 6;
		  else if(point > 8'b00000110)length = 5;
		  else if(point > 8'b00000001)length = 4;
		  else length = 3;

        // Refresh item position
        if (move_dir == 2'b00 || move_dir == 2'b01) begin
            item_x = X + 3'b011;
            item_y = Y - 3'b011;
        end else begin
            item_x = X - 3'b011;
            item_y = Y + 3'b011;
        end

     
    end
end

//counter
reg[3:0]A_Count;
wire CLK_div;
divfreq F0(SYS_CLK,CLK_div);

always@(posedge CLK_div,posedge PAUSE)
  if(PAUSE) A_Count<=4'b0000;
  else if(A_Count==4'b1001)A_Count<=4'b0000;
  else A_Count<=A_Count+1'b1;
  
always@(A_Count)
   case({A_Count})
		4'b0000:{a,b,c,d,e,f,g}=7'b0000001;
		4'b0001:{a,b,c,d,e,f,g}=7'b1001111;
		4'b0010:{a,b,c,d,e,f,g}=7'b0010010;
		4'b0011:{a,b,c,d,e,f,g}=7'b0000110;
		4'b0100:{a,b,c,d,e,f,g}=7'b1001100;
		4'b0101:{a,b,c,d,e,f,g}=7'b0100100;
		4'b0110:{a,b,c,d,e,f,g}=7'b0100000;
		4'b0111:{a,b,c,d,e,f,g}=7'b0001111;
		4'b1000:{a,b,c,d,e,f,g}=7'b0000000;
		4'b1001:{a,b,c,d,e,f,g}=7'b0000100;
		default:{a,b,c,d,e,f,g}=7'b1111111;
	endcase


endmodule

module divfreq(input CLK,output reg CLK_div);
reg[24:0] Count=25'b0;
always@(posedge CLK)
  begin
   if(Count>25000000)
	 begin
	  Count<=25'b0;
	  CLK_div<=~CLK_div;
	 end
   else
	 Count<=Count+1'b1;
	end
endmodule
