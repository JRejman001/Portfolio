LIBRARY ieee;
 USE ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 
entity Baud_Rate_Generator is
Generic(
	max_count : integer := 9600
	);
port(
	clock : in std_logic;
	reset : in std_logic;
	baudRateEnable : out std_logic;
	baudRateEnable_x16 : out std_logic
	);
end Baud_Rate_Generator;

architecture Zachowanie of 	Baud_Rate_Generator is
	signal counter : integer range 0 to max_count := 0;
	signal counter2 : integer range 0 to max_count/16 := 0;
	begin
	process(clock)
	begin
		if(rising_edge(clock)) then
			if(reset = '1') then
				counter <= 0;
				counter2 <= 0;
				baudRateEnable <= '0';
			else
				if(counter = max_count -1) then
					counter <= 0;
					baudRateEnable <= '1';
				elsif(counter < max_count/2 - 1) then
					counter <= counter + 1;
				else
					baudRateEnable <= '0';
					counter <= counter + 1;
				end if;
				if(counter2 = max_count/16 - 1) then
					counter2 <= 0;
					baudRateEnable_x16 <= '1';
				elsif(counter2 < max_count/32 - 1) then
					counter2 <= counter2 + 1;
				else
					counter2 <= counter2 + 1;
					baudRateEnable_x16 <= '0';
				end if;
			end if;
		end if;
	end process;
end Zachowanie;	