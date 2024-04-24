library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;


entity Control_Unit is
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
		;g_InstWord:integer:=52
		);
	port
		(i_Clk:in std_logic
		;i_Inst:in std_logic_vector(g_InstWord-1 downto 0)
		;i_execute:in std_logic
		;i_FinishGP:in std_logic
		;i_FinishCP:in std_logic
		;i_reset:in std_logic
		;o_Busy:out std_logic
		;o_Timer:out std_logic_vector(g_timer-1 downto 0)
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
		;o_staCP:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;o_staGP:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0)
		;o_staDA:out std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		;o_Mreset:out std_logic_vector(g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules-1 downto 0)
		);
end entity;

architecture rtl of Control_Unit is
	
	constant c_NumRegister:integer:=4*(g_AWGQD+g_RL*g_AWGQR)+g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+9;
	constant c_Const0:integer:=g_AWGQD+g_RL*g_AWGQR;
	constant c_Const1:integer:=g_Filter_n_Decimation_modules*g_samples+4*c_const0+4;
	constant c_Const2:integer:=c_const1+2*g_Demodulator_modules+g_Filter_n_Decimation_modules;
	constant c_NReg:integer:=integer(ceil(LOG2(real(c_NumRegister))));
	constant c_NAWG_modules:integer:=integer(ceil(LOG2(real(g_AWGQD+g_RL*g_AWGQR))));

	component FSM0 is
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
	end component;
	
	component WSelector is
		generic
			(g_bits:integer:=8
			);
		port
			(i_Data:in std_logic_vector(g_bits-1 downto 0)
			;i_W:in std_logic
			;o_Data:out std_logic_vector(2**g_bits-1 downto 0)
			);
	end component;
	
	component Setting_Registers is
		generic
			(g_bits:integer:=g_bits
			;g_samples:integer:=g_samples
			;g_Demodulator_modules:integer:=g_Demodulator_modules
			;g_Filter_n_Decimation_modules:integer:=g_Filter_n_Decimation_modules
			;g_FreePorts:integer:=g_FreePorts
			;g_ADCs:integer:=g_ADCs
			;Bus_Data_Width:integer:=Bus_Data_Width
			;g_lines:integer:=g_lines
			;g_addr:integer:=g_addr
			;g_AWGQD:integer:=g_AWGQD
			;g_AWGQR:integer:=g_AWGQR
			;g_RL:integer:=g_RL
			;g_DACs:integer:=g_DACs
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
	end component;
	
	component EData is
		generic
			(g_bits:integer:=16);
		port
			(i_Data:in std_logic_vector(g_bits-1 downto 0)
			;i_Enable:in std_logic
			;o_Data:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	
	
	
	signal s_Time:std_logic_vector(g_timer-1 downto 0);
	signal s_TimeComp:std_logic_vector(g_timer-1 downto 0);
	signal s_NotClk:std_logic;
	
	signal s_Inst:std_logic_vector(g_InstWord-1 downto 0);
	
	signal s_Tempo:std_logic;
	signal s_PulseSelect:std_logic;
	signal s_Timer:std_logic;
	signal s_op:std_logic_vector(1 downto 0);
	signal s_SubFinish:std_logic;
	signal s_RFinish:std_logic;
	signal s_WFinish:std_logic;
	signal s_Winst:std_logic;
	signal s_Wreg:std_logic;
	signal s_staCP:std_logic;
	signal s_staGP:std_logic;
	signal s_reset:std_logic;
	signal s_staSub:std_logic;
	signal s_staMemR:std_logic;
	signal s_staMemW:std_logic;
	signal s_staDA:std_logic;
	signal s_stopDA:std_logic;
	signal s_PFinish:std_logic;
	
	signal s_WfCGP:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	signal s_WalphaAWG:std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0);
	signal s_WbetaAWG:std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0);
	signal s_WcPulse:std_logic;
	signal s_WgainAWG:std_logic_vector(g_AWGQD + g_RL*g_AWGQR-1 downto 0);
	signal s_WcMUXAWG:std_logic;
	signal s_WcMUXDA0:std_logic;
	signal s_WcMUXDA1:std_logic;
	signal s_WgainDA:std_logic_vector(g_Filter_n_Decimation_modules*g_samples-1 downto 0);
	signal s_WalphaDA:std_logic_vector(g_Demodulator_modules-1 downto 0);
	signal s_WbetaDA:std_logic_vector(g_Demodulator_modules-1 downto 0);
	signal s_WDecimation:std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0);
	signal s_WTime:std_logic;
	signal s_WstaGP:std_logic;
	signal s_WstaCP:std_logic;
	signal s_WMreset:std_logic;
	signal s_WstaDA:std_logic;
	
	signal s_reg:std_logic_vector(c_NReg-1 downto 0);
	signal s_Nreg:std_logic_vector(2**c_NReg-1 downto 0);
	signal s_cPulse:std_logic_vector(2**c_NAWG_modules-1 downto 0);
	
	signal s_TempGP:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	signal s_TempCP:std_logic_vector(g_AWGQD+g_RL*g_AWGQR-1 downto 0);
	signal s_TempDA:std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0);
	
	signal s_Mreset:std_logic_vector(g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules-1 downto 0);
begin
	s_NotClk<=not(i_Clk);

	process(s_NotClk, i_reset)
		variable v_Temp:integer;
	begin
		if(i_reset='0') then
			v_Temp:=0;
		elsif(rising_edge(s_NotClk)) then
			v_Temp:=v_Temp+1;
		end if;
		s_Time<=std_logic_vector(to_unsigned(v_Temp,g_timer));
	end process;
	o_Timer<=s_Time;
	s_Timer<='1' when s_Time=s_TimeComp else
				'0';
	--Registro de instrucciones
	process(s_NotClk)
		variable v_Temp:std_logic_vector(g_InstWord-1 downto 0);
	begin
		if(rising_edge(s_NotClk)) then
			if(s_Winst='1') then
				v_Temp:=i_Inst;
			end if;
		end if;
		s_Inst<=v_Temp;
	end process;
	
	--Asocio algunos bits del registro de instrucciones a la senal de Tempo, OP y registro.
	s_Tempo<=s_Inst(g_InstWord-1);
	s_op<=s_Inst(g_InstWord-2 downto g_InstWord-3);
	s_reg<=s_Inst(g_InstWord-4 downto g_instWord-3-c_NReg);
	
	--Banco de registros
	SR:	Setting_Registers	port map (S_NotClk,s_Inst(Bus_Data_Width-1 downto 0),s_WfCGP,s_WalphaAWG,s_WbetaAWG,s_WcPulse,s_WgainAWG,s_WcMUXAWG
												,s_WcMUXDA0,s_WcMUXDA1,s_WgainDA,s_WalphaDA,s_WbetaDA,s_WDecimation,s_WTime,s_WstaGP,s_WstaCP
												,s_WMreset,s_WstaDA,i_reset,o_fCGP,o_alphaAWG
												,o_betaAWG,o_cPulse(g_AWGQD+g_RL*g_AWGQR-1 downto 0),o_gainAWG,o_cMUXAWG,o_cMUXDA0,o_cMUXDA1,o_gainDA
												,o_alphaDA,o_betaDA,o_Decimation,s_TimeComp,s_TempGP,s_TempCP,s_Mreset,s_TempDA);
	--Selector de registro para escritura
	WS:	WSelector	generic map (c_NReg)
							port map (s_reg,s_Wreg,s_Nreg);
	
	--Asociasiones importantes entre s_Nreg y las se;ales de escritura de cada uo de los registros
	A:	for i in 0 to g_AWGQD+g_RL*g_AWGQR-1 generate
			s_WfCGP(i)<=s_Nreg(i);
			s_WalphaAWG(i)<=s_Nreg(i+g_AWGQD+g_RL*g_AWGQR);
			s_WbetaAWG(i)<=s_Nreg(i+2*(g_AWGQD+g_RL*g_AWGQR));
			s_WgainAWG(i)<=s_Nreg(i+3*(g_AWGQD+g_RL*g_AWGQR)+1);
		end generate;
	s_WcPulse<=s_Nreg(3*(g_AWGQD+g_RL*g_AWGQR));
	s_WcMUXAWG<=s_Nreg(4*(g_AWGQD+g_RL*g_AWGQR)+1);
	s_WcMUXDA0<=s_Nreg(4*(g_AWGQD+g_RL*g_AWGQR)+2);
	s_WcMUXDA1<=s_Nreg(4*(g_AWGQD+g_RL*g_AWGQR)+3);
	s_WTime<=s_Nreg(g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+4);
	s_WstaGP<=s_Nreg(g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+5);
	s_WstaCP<=s_Nreg(g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+6);
	s_WMreset<=s_Nreg(g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+7);
	s_WstaDA<=s_Nreg(g_Filter_n_Decimation_modules*(g_samples+1)+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+8);
	B:	for i in 0 to g_Filter_n_Decimation_modules-1 generate
			BA:	for j in 0 to g_samples-1 generate
						s_WgainDA(i*g_samples+j)<=s_Nreg(i*g_samples+j+4*(g_AWGQD+g_RL*g_AWGQR)+4);
					end generate;
			s_WDecimation(i)<=s_Nreg(i+g_Filter_n_Decimation_modules*g_samples+2*g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+4);
		end generate;
	C:	for i in 0 to g_Demodulator_modules-1 generate
			s_WalphaDA(i)<=s_Nreg(i+g_Filter_n_Decimation_modules*g_samples+4*(g_AWGQD+g_RL*g_AWGQR)+4);
			s_WbetaDA(i)<=s_Nreg(i+g_Filter_n_Decimation_modules*g_samples+g_Demodulator_modules+4*(g_AWGQD+g_RL*g_AWGQR)+4);
		end generate;
	
	
	--Maquina de estados que ejecuta instrucciones
	ASM0:	FSM0	port map (i_Clk,i_execute,s_Tempo,s_Timer,s_op,s_PFinish,i_reset,s_Winst
								,s_Wreg,s_staCP,s_staGP,s_reset,s_staDA,o_Busy);
	
	--selector de pulsos gausianos a generar
	SGP:	EData	generic map (g_AWGQD+g_RL*g_AWGQR)
					port map (s_TempGP,s_staGP,o_staGP);
	--Selector de pulsos custom a generar
	SCP:	EDATA generic map (g_AWGQD+g_RL*g_AWGQR)
					port map (s_TempCP,s_staCP,o_staCP);
	
	--Selector de se;ales a generar
	SDA:	EData generic map (g_Filter_n_Decimation_modules)
					port map (s_TempDA,s_staDA,o_staDA);
	
	--Senal de sin de pulso
	s_PFinish<=i_FinishGP and i_FinishCP;
	
	--Selector de modulo a reiniciar
	SRE:	EData	generic map (g_AWGQD+g_RL*g_AWGQR+2*g_Filter_n_Decimation_modules+g_Demodulator_modules)
					port map (s_Mreset,s_reset,o_Mreset);
	
end rtl;