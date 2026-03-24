LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Transmiter is
port(
	rst : in std_logic;
	clock : in std_logic;
	BaudRateEnable : in std_logic;
	ParallelDataIn : in std_logic_vector (7 downto 0);
	TransmitRequest : in std_logic;
	Ready : out std_logic;
	SerialDataOut : out std_logic
);
end Transmiter;

architecture zachowanie of Transmiter is
	type maszyna_stanow is (oczekiwanie, bit_startu, przesylanie, bit_stopu, gotowy, reset);
	signal stan : maszyna_stanow := oczekiwanie;
	begin
	process(baudRateEnable)
	variable pamiec : std_logic_vector (7 downto 0):= "00000000";
	variable licznik : integer range 0 to 8 := 0;
	begin
	if(rising_edge(baudRateEnable)) then
		if (rst = '1') then
			stan <= reset;
		end if;
		case stan is
		when oczekiwanie =>
			if(TransmitRequest = '1') then
				pamiec := ParallelDataIn;
				Ready <= '0';
				stan <= bit_startu;
			end if;
			SerialDataOut <= '1';
		when bit_startu =>
			SerialDataOut <= '0';
			stan <= przesylanie;
		when przesylanie =>
			if(licznik < 7) then
				SerialDataOut <= pamiec(licznik);
				licznik := licznik + 1;
			else
				SerialDataOut <= pamiec(licznik);
				licznik := 0;
				stan <= bit_stopu;
			end if;
		when bit_stopu =>
			SerialDataOut <= '0';
			stan <= gotowy;
		when gotowy =>
			SerialDataOut <= '1';
			Ready <= '1';
			stan <= oczekiwanie;
		when reset =>
			pamiec := "00000000";
			licznik := 0;
			Ready <= '1';
			SerialDataOut <= '1';
			stan <= oczekiwanie;
		end case;
	end if;
	end process;	
end zachowanie;