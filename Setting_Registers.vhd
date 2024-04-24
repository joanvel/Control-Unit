library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

entity Setting_Registers is
	generic
		(g_bits:integer:=16
		;g_samples:integer:=10
		;g_Demodulator_modules:integer:=4
		;g_Filter_n_Decimation_modules:integer:=10
		;g_FreePorts:integer:=4
		;g_ADCs:integer:=2
		;Bus_Data_Width:integer:=40
		;g_lines:integer:=11
		;g_addr:integer:=11
		;g_AWGQD:integer:=4
		;g_AWGQR:integer:=3
		;g_RL:integer:=2
		;g_DACs:integer:=6
		;g_timer:integer:=20
		);
	port
		(i_Clk:in std_logic
		;i_Data:in std_logic_vector(Bus_Data_Width-1 downto 0)
		;i_WfCGP:in std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;i_WalphaAWG:in std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0)
		;i_WbetaAWG:in std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0)
		;i_WcPulse:in std_logic
		;i_WgainAWG:in std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0)
		;i_WcMUXAWG:in std_logic
		;i_WcMUXDA0:in std_logic
		;i_WcMUXDA1:in std_logic
		;i_WgainDA:in std_logic_vector(g_Filter_n_Decimation_modules*g_samples-1 downto 0)
		;i_WalphaDA:in std_logic_vector(g_Demodulator_modules-1 downto 0)
		;i_WbetaDA:in std_logic_vector(g_Demodulator_modules-1 downto 0)
		;i_WDecimation:in std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		;i_WTime:in std_logic
		;i_WstaGP:in std_logic
		;i_WstaCP:in std_logic
		;i_WMreset:in std_logic
		;i_WstaDA:in std_logic
		;i_reset:in std_logic
		;o_fCGP:out std_logic_vector(g_lines*(g_AWGQD+g_RL*g_AWGQR)-1 downto 0)
		;o_alphaAWG:out std_logic_vector(g_bits*(g_AWGQD + g_RL*g_AWGQR)-1 downto 0)
		;o_betaAWG:out std_logic_vector(g_bits*(g_AWGQD + g_RL*g_AWGQR)-1 downto 0)
		;o_cPulse:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;o_gainAWG:out std_logic_vector(g_bits*(g_AWGQD+g_RL*g_AWGQR)-1 downto 0)
		;o_cMUXAWG:out std_logic_vector(g_DACs*(integer(ceil(LOG2(real(3*g_AWGQD+2*g_RL)))))-1 downto 0)
		;o_cMUXDA0:out std_logic_vector(integer(ceil(LOG2(real(g_ADCs+g_Filter_n_Decimation_modules))))*(g_Demodulator_modules+g_FreePorts)-1 downto 0)
		;o_cMUXDA1:out std_logic_vector(integer(ceil(LOG2(real(2*g_Demodulator_modules+g_FreePorts))))*g_Filter_n_Decimation_modules-1 downto 0)
		;o_gainDA:out std_logic_vector(g_Filter_n_Decimation_modules*g_samples*g_bits-1 downto 0)
		;o_alphaDA:out std_logic_vector(g_Demodulator_modules*g_bits-1 downto 0)
		;o_betaDA:out std_logic_vector(g_Demodulator_modules*g_bits-1 downto 0)
		;o_Decimation:out std_logic_vector(g_Filter_n_Decimation_modules*g_bits-1 downto 0)
		;o_Time:out std_logic_vector(g_timer-1 downto 0)
		;o_staGP:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;o_staCP:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;o_Mreset:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules-1 downto 0)
		;o_staDA:out std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		);
end entity;

architecture rtl of Setting_Registers is
	constant c_const0:integer:=g_DACs*(integer(ceil(LOG2(real(3*g_AWGQD+2*g_RL)))));
	constant c_const1:integer:=integer(ceil(LOG2(real(g_ADCs+g_Filter_n_Decimation_modules))))*(g_Demodulator_modules+g_FreePorts);
	constant c_const2:integer:=integer(ceil(LOG2(real(2*g_Demodulator_modules+g_FreePorts))))*g_Filter_n_Decimation_modules;
	
	type t_fGP is array (0 to g_AWGQD+g_RL*g_AWGQR-1) of std_logic_vector(g_lines-1 downto 0);
	type t_fControlQD is array (0 to g_AWGQD+g_RL*g_AWGQR-1) of std_logic_vector(g_bits-1 downto 0);
	type t_gainQR0 is array (0 to g_samples-1) of std_logic_vector(g_bits-1 downto 0);
	type t_gainQR is array (0 to g_Filter_n_Decimation_modules-1) of t_gainQR0;
	type t_fControlQR is array (0 to g_Demodulator_modules-1) of std_logic_vector(g_bits-1 downto 0);
	type t_Decimator is array (0 to g_Filter_n_Decimation_modules-1) of std_logic_vector(g_bits-1 downto 0);
	
	signal s_fGP:t_fGP;
	signal s_alphaAWG:t_fControlQD;
	signal s_betaAWG:t_fControlQD;
	signal s_gainAWG:t_fControlQD;
	signal s_gainDA:t_gainQR;
	signal s_alphaDA:t_fControlQR;
	signal s_betaDA:t_fControlQR;
	signal s_Decimator:t_Decimator;
begin
	A:	for i in 0 to g_AWGQD+g_RL*g_AWGQR-1 generate
			--Registros que controlan la longitud del pulso gaussiano
			o_fCGP((i+1)*g_lines-1 downto i*g_lines)<=s_fGP(i);
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_lines-1 downto 0);
			begin
				if (i_reset='0') then
					v_Temp:=(others=>'0');
				elsif (rising_edge(i_Clk)) then
					if(i_WfCGP(i)='1') then
						v_Temp:=i_Data(g_lines-1 downto 0);
					end if;
				end if;
				s_fGP(i)<=v_Temp;
			end process;
			
			--Registros que controlan la señal Alpha de las señales sinusoidales
			o_alphaAWG((i+1)*g_bits-1 downto i*g_bits)<=s_alphaAWG(i);
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WalphaAWG(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_alphaAWG(i)<=v_Temp;
			end process;
			
			--Registros que controlan la señal Beta de las señales sinusoidales
			o_betaAWG((i+1)*g_bits-1 downto i*g_bits)<=s_betaAWG(i);
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WbetaAWG(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_betaAWG(i)<=v_Temp;
			end process;
			
			--Registros de ganancias de los pulsos
			o_gainAWG((i+1)*g_bits-1 downto i*g_bits)<=s_gainAWG(i);
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WgainAWG(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_gainAWG(i)<=v_Temp;
			end process;
		end generate;
		
		
	--Registro de selección de pulsos de cada uno de los bloques
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WcPulse='1') then
				v_Temp:=i_Data(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
			end if;
		end if;
		o_cPulse<=v_Temp;
	end process;
	
	--Registro de control para el bloque de multiplexores de la unidad de AWGs
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(c_const0-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WcMUXAWG='1') then
				v_Temp:=i_Data(c_const0-1 downto 0);
			end if;
		end if;
		o_cMUXAWG<=v_Temp;
	end process;
	
	--Registro de control del primer bloque de multiplexores de la unidad de DA
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(c_const1-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WcMUXDA0='1') then
				v_Temp:=i_Data(c_const1-1 downto 0);
			end if;
		end if;
		o_cMUXDA0<=v_Temp;
	end process;
	
	--Registro de control del segundo bloque de multiplexores de la unidad de DA
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(c_const2-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WcMUXDA1='1') then
				v_Temp:=i_Data(c_const2-1 downto 0);
			end if;
		end if;
		o_cMUXDA1<=v_Temp;
	end process;
	
	B:	for i in 0 to g_Filter_n_Decimation_modules-1 generate
			BA:	for j in 0 to g_samples-1 generate
			
						--Registros de ganacias para las muestras de la señal de entrada
						o_gainDA((i*g_samples+j+1)*g_bits-1 downto (i*g_samples+j)*g_bits)<=s_gainDA(i)(j);
						process(i_Clk,i_reset)
							variable v_Temp:std_logic_vector(g_bits-1 downto 0);
						begin
							if(i_reset='0') then
								v_Temp:=(others=>'0');
							elsif(rising_edge(i_Clk)) then
								if(i_WgainDA(i*g_samples+j)='1') then
									v_Temp:=i_Data(g_bits-1 downto 0);
								end if;
							end if;
							s_gainDA(i)(j)<=v_Temp;
						end process;
					end generate;
					
			--Registros de valor de decimación
			o_Decimation((i+1)*g_bits-1 downto i*g_bits)<=s_Decimator(i);
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WDecimation(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_Decimator(i)<=v_Temp;
			end process;
					
		end generate;
	
	C:	for i in 0 to g_Demodulator_modules-1 generate
			o_alphaDA((i+1)*g_bits-1 downto i*g_bits)<=s_alphaDA(i);
			--Registros de las señales alpha de la unidad de DA
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WalphaDA(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_alphaDA(i)<=v_Temp;
			end process;
			
			o_betaDA((i+1)*g_bits-1 downto i*g_bits)<=s_betaDA(i);
			--Registros de las señales beta de la unidad de DA
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if(i_reset='0') then
					v_Temp:=(others=>'0');
				elsif(rising_edge(i_Clk)) then
					if(i_WbetaDA(i)='1') then
						v_Temp:=i_Data(g_bits-1 downto 0);
					end if;
				end if;
				s_betaDA(i)<=v_Temp;
			end process;
		end generate;
	
	--Registro de tiempo a comparar
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_timer-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WTime='1') then
				v_Temp:=i_Data(g_timer-1 downto 0);
			end if;
		end if;
		o_Time<=v_Temp;
	end process;
	
	--Registro de inicio de pulsos gaussiano
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WstaGP='1') then
				v_Temp:=i_Data(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
			end if;
		end if;
		o_staGP<=v_Temp;
	end process;
	
	--Registro de inicio de pulsos custom
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WstaCP='1') then
				v_Temp:=i_Data(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
			end if;
		end if;
		o_staCP<=v_Temp;
	end process;
	
	--Registro de reinicio de modulos
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WMreset='1') then
				v_Temp:=i_Data(g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules-1 downto 0);
			end if;
		end if;
		o_Mreset<=v_Temp;
	end process;
	
	--Registro de inicio de modulos DA
	process(i_Clk,i_reset)
		variable v_Temp:std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0);
	begin
		if(i_reset='0') then
			v_Temp:=(others=>'0');
		elsif(rising_edge(i_Clk)) then
			if(i_WstaDA='1') then
				v_Temp:=i_Data(g_Filter_n_Decimation_modules-1 downto 0);
			end if;
		end if;
		o_staDA<=v_Temp;
	end process;
end rtl;