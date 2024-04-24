library ieee;
use ieee.std_logic_1164.all;

entity EData is
	generic
		(g_bits:integer:=8);
	port
		(i_Data:in std_logic_vector(g_bits-1 downto 0)
		;i_Enable:in std_logic
		;o_Data:out std_logic_vector(g_bits-1 downto 0)
		);
end entity;

architecture rtl of EData is

begin
	A:	for i in 0 to g_bits-1 generate
			o_Data(i)<=i_Data(i) and i_Enable;
		end generate;
end rtl;