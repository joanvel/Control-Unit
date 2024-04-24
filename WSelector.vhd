library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity WSelector is
	generic
		(g_bits:integer:=8
		);
	port
		(i_Data:in std_logic_vector(g_bits-1 downto 0)
		;i_W:in std_logic
		;o_Data:out std_logic_vector(2**g_bits-1 downto 0)
		);
end entity;

Architecture rtl of WSelector is
	signal s_Data:std_logic_vector(2**g_bits-1 downto 0);
begin
	--Demultiplexor
	process(i_Data)
	begin
		s_Data<=(others=>'0');
		s_Data(to_integer(unsigned(i_Data)))<='1';
	end process;
	
	--Serie de ands
	process(i_W,s_Data)
	begin
		for i in 0 to 2**g_bits-1 loop
			o_Data(i)<=i_W and s_Data(i);
		end loop;
	end process;
	
end rtl;