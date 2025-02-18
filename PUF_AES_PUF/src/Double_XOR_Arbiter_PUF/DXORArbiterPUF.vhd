library ieee;
use ieee.std_logic_1164.all;

entity DXORArbiterPUF is 
	generic (MaxChallenges: integer := 108); --N-Bit generic
	port(
		CLK        : in  std_logic;
		RST        : in  std_logic;
		Input	     : in  std_logic;  --initial input bit for MUX
		Challenge  : in  std_logic_vector(MaxChallenges-1 downto 0);  --N-bit Challenge 
		Response   : out std_logic);
end entity;

architecture Structural of DXORArbiterPUF is
-------------------------------------------------------------------------------
-- Component Instantiations
-------------------------------------------------------------------------------
	component MUX21
		port(
			A   : in  std_logic;
			B   : in  std_logic;
			SEL : in  std_logic; --Current challenge bit
			Y   : out std_logic);
	end component;
	
	component DFlipFlop is
		port(
			D,CLK  : in std_logic;
			Q      : out std_logic);
	end component;
	
-------------------------------------------------------------------------------
-- Signals, Constants, Attributes
-------------------------------------------------------------------------------
	signal R   : std_logic;
	signal v,w      	: std_logic_vector(MaxChallenges-1 downto 0); --Mux output/input signals 
--	attribute syn_keep: boolean;
--	attribute syn_keep of ArbiterPUF: entity is true;
--	attribute keep: boolean;
--	attribute noprune: boolean;
--	attribute preserve: boolean;
--	attribute keep of MUX21: component is true;
--	attribute preserve of MUX21: component is true;
--	attribute noprune of MUX21: component is true;
--	attribute keep of DFlipFlop: component is true;
--	attribute noprune of DFlipFlop: component is true;
--	attribute preserve of DFlipFlop: component is true;

-------------------------------------------------------------------------------
-- Architecture [Arbiter PUF]
-------------------------------------------------------------------------------
begin
--For-Genenerate loop used to iterate through the "MaxChallenges" amount of 
--MUX pairs to generate a 1-bit response.
--Three conditions states added to properly output the current "v" and "w"
--signal values and pass in their past generated values into the next MUX
--pair.

--At the Initial_State: 
--Input signal passes through the first MUX pair and generates the current 
--"v" and "w" outputs

--At the Main_State: 
--The past "v" and "w" values are passed through the second MUX pair down to 
--the penultimate MUX pair and generates the current "v" and "w" outputs

--At the Final_State: 
--The past "v" and "w" values are passed through the last_active MUX pair. The 
--final generated "v" and "w" values are passed into the DFlipFlop D and 
--Clock terminals to generate a 1-bit response.
 
	GEN:
	for i in 0 to (MaxChallenges) generate
		Initial_State: if (i = 0) generate
			M1  : MUX21 port map(A=>Input, B=>Input,SEL=>Challenge(i),Y=>v(i));
			M2  : MUX21 port map(A=>Input, B=>Input,SEL=>Challenge(i),Y=>w(i));
		end generate Initial_State;
		
		Main_State: if ((i > 0 AND i < (MaxChallenges-1))) generate
			M3  : MUX21 port map(A=>v(i-1), B=>w(i-1),SEL=>Challenge(i),Y=>v(i));
			M4  : MUX21 port map(A=>w(i-1), B=>v(i-1),SEL=>Challenge(i),Y=>w(i));
		end generate Main_State;
		
		Final_State: if (i = (MaxChallenges-1)) generate
			M5  : MUX21 port map(A=>v(i-1), B=>w(i-1),SEL=>Challenge(i),Y=>v(i));
			M6  : MUX21 port map(A=>w(i-1), B=>v(i-1),SEL=>Challenge(i),Y=>w(i));
			DFF : DFlipFlop port map (D=>v(i), CLK=>w(i), Q=>R);
		end generate Final_State;
	end generate GEN;
	Response <= R;
end architecture; 