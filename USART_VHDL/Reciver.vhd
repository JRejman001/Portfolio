LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Reciver is
port(
	rst : in std_logic;
	clock : in std_logic;
	serialDataIn : in std_logic;
	baudRate_x16 : in std_logic;
	ind : out std_logic_vector (7 downto 0);
	parallelDataOut : out std_logic_vector (7 downto 0);
	dataValid : out std_logic
);
end Reciver;

architecture zachowanie of Reciver is
type maszyna_stanow is (oczekiwanie, bit_startu, zapis, bit_stopu, reset);
signal stan : maszyna_stanow := oczekiwanie;
begin
	process(baudRate_x16)
	variable counter : integer range 0 to 15 := 0;
	variable pamiec : std_logic_vector (7 downto 0):= "00000000";
	variable index : integer range 0 to 8 := 0;
	begin
	if(rising_edge(baudRate_x16)) then
	if(rst = '1') then
		stan <= reset;
	end if;
		case stan is
		when oczekiwanie =>
			if(serialDataIn = '0') then
				stan <= bit_startu;
			end if;
			parallelDataOut <= pamiec;
		when bit_startu =>
			if(baudRate_x16 = '1') then
				if(counter < 8) then
					counter := counter + 1;
				else
					if(serialDataIn = '0') then
						stan <= zapis;
					else						
						stan <= oczekiwanie;
					end if;	
					counter := 0;	
				end if;
			end if;
		when zapis =>
			if(baudRate_x16 = '1') then
				if(counter < 15) then
					counter := counter + 1;
				elsif(index < 8) then
					pamiec(index) := serialDataIn;
					index := index + 1;
					counter := 0;
				else
					index := 0;
					counter := 0;
					stan <= bit_stopu;
				end if;
			end if;
			ind <= std_logic_vector(to_unsigned(index, 8));
		when bit_stopu =>
			if(baudRate_x16 = '1') then
				if(counter < 15) then
					counter := counter + 1;
				else
					if(serialDataIn = '0') then
						dataValid <= '1';
						stan <= oczekiwanie;
					else 
						dataValid <= '0';
						stan <= reset;
					end if;
				end if;
			end if;	
		when reset =>
			pamiec := "00000000";
			parallelDataOut <= "00000000";
			dataValid <= '0';
			stan <= oczekiwanie;
		end case;
	end if;		
	end process;
end zachowanie;