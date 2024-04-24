-- Quartus Prime VHDL Template
-- Four-State Moore State Machine

-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity FSM0 is

	port
		(i_clk:in std_logic
		;i_execute:in std_logic
		;i_Tempo: in std_logic
		;i_Time:in std_logic
		;i_op:in std_logic_vector(1 downto 0)
		;i_PFinish:in std_logic
		;reset	 : in	std_logic
		;o_Winst: out std_logic
		;o_Wreg: out std_logic
		;o_staCP: out std_logic
		;o_staGP: out std_logic
		;o_reset: out std_logic
		;o_staDA: out std_logic
		;o_Busy: out std_logic
		);

end entity;

architecture rtl of FSM0 is

	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2, s3, s4, s5, s6);

	-- Register to hold the current state
	signal state   : state_type;

begin

	-- Logic to advance to the next state
	process (i_clk, reset)
	begin
		if reset = '0' then
			state <= s0;
		elsif (rising_edge(i_clk)) then
			case state is
				when s0=>
					if i_execute='0' then
						state<=s0;
					else
						state<=s1;
					end if;
				when s1=>
					if i_Tempo='1' then
						state<=s2;
					else
						if i_op="00" then
							state<=s3;
						elsif i_op="01" then
							state<=s4;
						elsif i_op="10" then
							state<=s5;
						else
							state<=s6;
						end if;
					end if;
				when s2=>
					if i_Time='0' then
						state<=s2;
					else
						if i_op="00" then
							state<=s3;
						elsif i_op="01" then
							state<=s4;
						elsif i_op="10" then
							state<=s5;
						else
							state<=s6;
						end if;
					end if;
				when s3=>
					state<=s0;
				when s4=>
					if(i_PFinish='0') then
						state<=s4;
					else
						state<=s0;
					end if;
				when s5=>
					state<=s0;
				when s6=>
					state<=s0;
				when others=>
					NULL;
			end case;
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
	begin
		case state is
			when s0 =>
				o_Winst<='0';
				o_Wreg<='0';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='0';
				o_staDA<='0';
				o_Busy<='0';
			when s1 =>
				o_Winst<='1';
				o_Wreg<='0';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='0';
				o_staDA<='0';
				o_Busy<='1';
			when s2 =>
				o_Winst<='0';
				o_Wreg<='0';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='0';
				o_staDA<='0';
				o_Busy<='1';
			when s3 =>
				o_Winst<='0';
				o_Wreg<='1';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='0';
				o_staDA<='0';
				o_Busy<='1';
			when s4 =>
				o_Winst<='0';
				o_Wreg<='0';
				o_staCP<='1';
				o_staGP<='1';
				o_reset<='0';
				o_staDA<='0';
				o_Busy<='1';
			when s5 =>
				o_Winst<='0';
				o_Wreg<='0';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='1';
				o_staDA<='0';
				o_Busy<='1';
			when s6 =>
				o_Winst<='0';
				o_Wreg<='0';
				o_staCP<='0';
				o_staGP<='0';
				o_reset<='0';
				o_staDA<='1';
				o_Busy<='1';
			when others=>
				NULL;
		end case;
	end process;

end rtl;
