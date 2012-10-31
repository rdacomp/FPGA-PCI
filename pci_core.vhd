-- * Copyright (C) 2012 by ZhangJiPing
-- * All rights reserved.
-- *
-- * @Author:ZhangJiPing
-- *
-- * This program is free software; you can redistribute it and/or
-- * modify it under the terms of the GNU General Public License as
-- * published by the Free Software Foundation; either version 2 of
-- * the License, or (at your option) any later version.
-- *
-- * This program is distributed in the hope that it will be useful,
-- * but WITHOUT ANY WARRANTY; without even the implied warranty of
-- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- * GNU General Public License for more details.
-- *
-- * You should have received a copy of the GNU General Public License
-- * along with this program; if not, write to the Free Software
-- * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
-- * MA 02111-1307 USA
-- *
-- * @History:
-- * ZhangJiPing <cn.zhangJP@gmail.com> 
-----------------------------------------------------------------------------------------------------------
--Base2'Base3'Base4 and Base5 is memory space
-----------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
entity pci_core is
    generic(
        DEVICE_ID                               :       std_logic_vector(15 downto 0)   ;
        VENDOR_ID                               :       std_logic_vector(15 downto 0)   ;
        CLASS_CODE                              :       std_logic_vector(15 downto 0)   ;
        SYS_DEVICE_ID                           :       std_logic_vector(15 downto 0)   ;
        SYS_VENDOR_ID                           :       std_logic_vector(15 downto 0)   ;
        REVISION_ID                             :       std_logic_vector(15 downto 0)   ;
        COMMAND                                 :       std_logic_vector(15 downto 0)   ;
        STATUS                                  :       std_logic_vector(15 downto 0)   ;
        
        LOCAL_DBUS_WIDE                         :       integer range 0 to 127          ;
        BaseAddress0Size                        :       integer                         ;
        BaseAddress1Size                        :       integer                         ;
        BaseAddress2Size                        :       integer                         ;
        BaseAddress3Size                        :       integer                         ;
        BaseAddress4Size                        :       integer                         ;
        BaseAddress5Size                        :       integer                         ;
        Bar0SpaceType                           :       std_logic                       ;
        Bar1SpaceType                           :       std_logic                       ;
        Bar2SpaceType                           :       std_logic                       ;
        Bar3SpaceType                           :       std_logic                       ;
        Bar4SpaceType                           :       std_logic                       ;
        Bar5SpaceType                           :       std_logic
        );
    port (
        clk	                                : in    std_logic                                       ;
        rstn	                                : in    std_logic                                       ;
        idsel	                                : in    std_logic                                       ;
        framen	                                : inout std_logic                                       ;
        irdyn	                                : in    std_logic                                       ;
        devseln	                                : inout std_logic                                       ;
        trdyn	                                : inout std_logic                                       ;
        stopn	                                : inout std_logic                                       ;
        intan	                                : out   std_logic                                       ;
        serrn	                                : out   std_logic                                       ;
        cben	                                : inout std_logic_vector (3 downto 0)                   ;
        par	                                : inout std_logic                                       ;
        perrn	                                : inout std_logic                                       ;
        req 					: out 	std_logic                                       ;
        gnt 					: in 	std_logic                                       ;
        ad                                      : inout std_logic_vector(31 downto 0)                   ;

        local_cs                                : out   std_logic_vector(5 downto 0)                    ;
        local_wr                                : out   std_logic                                       ;
        local_rd                                : out   std_logic                                       ;
        local_ab                                : out   std_logic_vector(31 downto 0)                   ;
        local_rdb                               : in    std_logic_vector(LOCAL_DBUS_WIDE-1 downto 0)    ;
        local_wdb                               : out   std_logic_vector(LOCAL_DBUS_WIDE-1 downto 0)    ;
        local_req_dma                           : in    std_logic 
        );
end pci_core;

architecture one of pci_core is
    constant    DMAMODE0                        :       std_logic_vector := x"00000043";
    constant    DMACRS0                         :       std_logic_vector := x"10";
    constant    ConfigRead                      :       std_logic_vector := b"1010";
    constant    ConfigWrite                     :       std_logic_vector := b"1011";
    constant    IO_Read                         :       std_logic_vector := b"0010";
    constant    IO_Write                        :       std_logic_vector := b"0011";
    constant    Memory_Read                     :       std_logic_vector := b"0110";
    constant    Memory_Write                    :       std_logic_vector := b"0111";
    constant    IDLE                            :       std_logic_vector := x"00";
    constant    ConfigAccess                    :       std_logic_vector := x"01";
    constant    ReadAccess2                     :       std_logic_vector := x"02";
    constant    ReadAccess3                     :       std_logic_vector := x"03";
    constant    ReadAccess4                     :       std_logic_vector := x"04";
    constant    ReadAccess5                     :       std_logic_vector := x"05";
    
    constant    WriteAccess2                    :       std_logic_vector := x"06";
    constant    WriteAccess3                    :       std_logic_vector := x"07";
    constant    WriteAccess4                    :       std_logic_vector := x"08";
    constant    WriteAccess5                    :       std_logic_vector := x"09";
    constant    WriteAccess6                    :       std_logic_vector := x"0a";
    
    signal      PCI_OperationPhases             :       std_logic_vector(7 downto 0)    := x"00";

    signal      OutToPciRegister                :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      AddressRegister                 :       std_logic_vector(31 downto 0)   := x"00000000";
    
    signal      wbBaseAddressRegister0          :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      wbBaseAddressRegister1          :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      wbBaseAddressRegister2          :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      wbBaseAddressRegister3          :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      wbBaseAddressRegister4          :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      wbBaseAddressRegister5          :       std_logic_vector(31 downto 0)   := x"00000000";
    
    signal      start_BaseAddressRegister0      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister0        :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      start_BaseAddressRegister1      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister1        :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      start_BaseAddressRegister2      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister2        :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      start_BaseAddressRegister3      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister3        :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      start_BaseAddressRegister4      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister4        :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      start_BaseAddressRegister5      :       std_logic_vector(31 downto 0)   := x"00000000";
    signal      end_BaseAddressRegister5        :       std_logic_vector(31 downto 0)   := x"00000000";
    
    signal      ConfigReadPhase                 :       std_logic_vector(3  downto 0)   := x"0"         ;
    signal      ConfigWritePhase                :       std_logic_vector(3  downto 0)   := x"0"         ;
    signal      IO_ReadPhase                    :       std_logic_vector(3  downto 0)   := x"0"         ;
    signal      IO_WritePhase                   :       std_logic_vector(3  downto 0)   := x"0"         ;
    signal      Memory_ReadPhase                :       std_logic_vector(3  downto 0)   := x"0"         ;
    signal      Memory_WritePhase               :       std_logic_vector(3  downto 0)   := x"0"         ;
    
    signal      AddressLocalAB                  :       std_logic_vector(31 downto 0)   := x"00000000"  ;
    signal      AddressLocalWdb                 :       std_logic_vector(31 downto 0)   := x"00000000"  ;
    signal      trdyn_status                    :       std_logic                                       ;
    signal      local_ab_wide                   :       integer range 0 to 127          := 0            ;
    signal      local_cs_status                 :       std_logic_vector(5 downto 0)    := b"000000"    ;
    signal      gnt_status                      :       std_logic                       := '0'          ;
begin
    intan                               <=      '1';
    gnt_status                          <=      gnt;

    AddressRegister                     <=      ad                      when framen = '0' and (clk'event and clk = '0') else
                                                AddressRegister;

    ad                                  <=      OutToPciRegister        when (IO_ReadPhase = IO_Read or Memory_ReadPhase = Memory_Read or ConfigReadPhase = ConfigRead) and irdyn = '0'else       x"ZZZZZZZZ";

    start_BaseAddressRegister0          <=      wbBaseAddressRegister0  when irdyn'event and irdyn = '1'and wbBaseAddressRegister0 /= x"00000000" else
                                                start_BaseAddressRegister0;

    end_BaseAddressRegister0            <=      start_BaseAddressRegister0 + (2**BaseAddress0Size)/4 when irdyn'event and irdyn = '1'and  start_BaseAddressRegister0 /= x"00000000" else
                                                end_BaseAddressRegister0;

    start_BaseAddressRegister1          <=      wbBaseAddressRegister1 and x"fffffffe"  when irdyn'event and irdyn = '1'and wbBaseAddressRegister1  /= x"00000000" else
                                                start_BaseAddressRegister1;

    end_BaseAddressRegister1            <=      start_BaseAddressRegister1 + (2**BaseAddress1Size)/4 when irdyn'event and irdyn = '1'and start_BaseAddressRegister1 /= x"00000000" else
                                                end_BaseAddressRegister1;

    start_BaseAddressRegister2          <=      wbBaseAddressRegister2  when irdyn'event and irdyn = '1'and wbBaseAddressRegister2     /= x"00000000" else
                                                start_BaseAddressRegister2;

    end_BaseAddressRegister2            <=      start_BaseAddressRegister2 + (2**BaseAddress2Size)/4 when irdyn'event and irdyn = '1'and start_BaseAddressRegister2 /= x"00000000" else
                                                end_BaseAddressRegister2;

    start_BaseAddressRegister3          <=      wbBaseAddressRegister3  when irdyn'event and irdyn = '1'and wbBaseAddressRegister3     /= x"00000000" else
                                                start_BaseAddressRegister3;

    end_BaseAddressRegister3            <=      start_BaseAddressRegister3 + (2**BaseAddress3Size)/4 when irdyn'event and irdyn = '1'and start_BaseAddressRegister3 /= x"00000000" else
                                                end_BaseAddressRegister3;

    start_BaseAddressRegister4          <=      wbBaseAddressRegister4  when irdyn'event and irdyn = '1'and wbBaseAddressRegister4     /= x"00000000" else
                                                start_BaseAddressRegister4;

    end_BaseAddressRegister4            <=      start_BaseAddressRegister4 + (2**BaseAddress4Size)/4 when irdyn'event and irdyn = '1'and start_BaseAddressRegister4 /= x"00000000" else
                                                end_BaseAddressRegister4;

    start_BaseAddressRegister5          <=      wbBaseAddressRegister5  when irdyn'event and irdyn = '1'and wbBaseAddressRegister5     /= x"00000000" else
                                                start_BaseAddressRegister5;

    end_BaseAddressRegister5            <=      start_BaseAddressRegister5 + (2**BaseAddress5Size)/4 when irdyn'event and irdyn = '1'and start_BaseAddressRegister5 /= x"00000000" else
                                                end_BaseAddressRegister5;
    
    AddressLocalAB(29 downto 0)         <=      AddressRegister(31 downto 2 ) - start_BaseAddressRegister0(31 downto 2)
when AddressRegister >= start_BaseAddressRegister0 and AddressRegister <=end_BaseAddressRegister0
else
                                                AddressRegister(31 downto 2 ) - start_BaseAddressRegister1(31 downto 2)
when AddressRegister >= start_BaseAddressRegister1 and AddressRegister <=end_BaseAddressRegister1
else
                                                AddressRegister(31 downto 2 ) - start_BaseAddressRegister2(31 downto 2)
when AddressRegister >= start_BaseAddressRegister2 and AddressRegister <=end_BaseAddressRegister2
else
                                                AddressRegister(31 downto 2 ) - start_BaseAddressRegister3(31 downto 2)
when AddressRegister >= start_BaseAddressRegister3 and AddressRegister <=end_BaseAddressRegister3
else
                                                AddressRegister(31 downto 2 ) - start_BaseAddressRegister4(31 downto 2)
when AddressRegister >= start_BaseAddressRegister4 and AddressRegister <=end_BaseAddressRegister4
else
                                                AddressRegister(31 downto 2 ) - start_BaseAddressRegister5(31 downto 2)
when AddressRegister >= start_BaseAddressRegister5 and AddressRegister <=end_BaseAddressRegister5
else
                                                AddressLocalAB(29 downto 0);

    local_cs_status(0)                          <=      '0' when PCI_OperationPhases /= x"0" and AddressRegister >= start_BaseAddressRegister0 and AddressRegister<=end_BaseAddressRegister0 else
                                               '1';
    local_cs_status(1)                          <=      '0' when PCI_OperationPhases /= x"0" and AddressRegister >= start_BaseAddressRegister1 and AddressRegister<=end_BaseAddressRegister1 else
                                               '1';
    local_cs_status(2)                          <=      '0' when PCI_OperationPhases /= x"0" and AddressRegister >= start_BaseAddressRegister2 and AddressRegister<=end_BaseAddressRegister2 else
                                               '1';
    local_cs_status(3)                          <=      '0' when PCI_OperationPhases /= x"0" and  AddressRegister >= start_BaseAddressRegister3 and AddressRegister<=end_BaseAddressRegister3 else
                                               '1';
    local_cs_status(4)                          <=      '0' when PCI_OperationPhases /= x"0" and  AddressRegister >= start_BaseAddressRegister4 and AddressRegister<=end_BaseAddressRegister4 else
                                               '1';
    local_cs_status(5)                          <=      '0' when PCI_OperationPhases /= x"0" and  AddressRegister >= start_BaseAddressRegister5 and AddressRegister<=end_BaseAddressRegister5 else
                                               '1';
    local_ab                                    <=      AddressLocalAB;
    local_wdb(LOCAL_DBUS_WIDE-1 downto 0)       <=      AddressLocalWdb(LOCAL_DBUS_WIDE-1 downto 0);
    stopn                                       <=      '1';
    par                                         <=      '1';
    trdyn                                       <=      trdyn_status;
    serrn                                       <=      '1';
    perrn                                       <=      '1';
    local_cs                                    <=      local_cs_status;
    req                                         <=      local_req_dma;

    process(PCI_OperationPhases,Memory_ReadPhase)
    begin
        if PCI_OperationPhases >= ReadAccess3 then
            if Memory_ReadPhase = Memory_Read or IO_ReadPhase = IO_Read then
                local_rd        <= '0';
            end if;
        else
            local_rd      <= '1';
        end if;
    end process;

    process(PCI_OperationPhases,Memory_WritePhase)
    begin
        if PCI_OperationPhases /= x"0" then
            if Memory_WritePhase = Memory_Write or IO_WritePhase = IO_Write then
                local_wr        <= '0';
            else
                null;
            end if;
        else
            local_wr      <= '1';
        end if;
    end process;

    process(framen,cben,trdyn_status)
    begin
        if framen = '0' then
            if cben = IO_Read then
                IO_ReadPhase <= cben;
            end if;
        else
            if trdyn_status'event and trdyn_status = '1' then
                IO_ReadPhase <= x"0";
            end if;
        end if;
    end process;

    process(framen,cben,trdyn_status)
    begin
        if framen = '0' then
            if cben = IO_Write then
                IO_WritePhase <= cben;
            else
                null;
            end if;
        else
            if trdyn_status'event and trdyn_status = '1' then
                IO_WritePhase   <= x"0";
            end if;
        end if;
    end process;

    
    process(framen,cben,trdyn_status)
    begin
        if framen = '0' then
            if cben = Memory_Read then
                Memory_ReadPhase <= cben;
            end if;
        else
            if trdyn_status'event and trdyn_status = '1' then
                Memory_ReadPhase <= x"0";
            end if;
        end if;
    end process;

    process(framen,cben,trdyn_status)
    begin
        if framen = '0' then
            if cben = Memory_Write then
                Memory_WritePhase <= cben;
            else
                null;
            end if;
        else
            if trdyn_status'event and trdyn_status = '1' then
                Memory_WritePhase <= x"0";
            end if;
        end if;
    end process;

    process(clk,framen,cben,idsel,irdyn,trdyn_status)
    begin
        if trdyn_status = '0' then
            ConfigWritePhase    <= x"0";
        else
            if clk'event and clk = '0'then
                if framen = '0' and idsel = '1' and cben = ConfigWrite then
                    ConfigWritePhase <= cben;
                end if;
            end if;
        end if;
    end process;
    
    process(clk,framen,cben,idsel,trdyn_status)
    begin
        if trdyn_status = '0' then
            ConfigReadPhase <= x"0";
        else
            if clk'event and clk ='0'then
                if framen = '0' and idsel = '1' and cben = ConfigRead then
                    ConfigReadPhase <= cben;
                end if;
            end if;
        end if;
    end process;

    process(clk,rstn,ad,irdyn,wbBaseAddressRegister0,wbBaseAddressRegister1,wbBaseAddressRegister2,wbBaseAddressRegister3,wbBaseAddressRegister4,wbBaseAddressRegister5)
    begin
        if rstn = '0' then
            wbBaseAddressRegister0      <= x"00000000";
            wbBaseAddressRegister1      <= x"00000000";
            wbBaseAddressRegister2      <= x"00000000";
            wbBaseAddressRegister3      <= x"00000000";
            wbBaseAddressRegister4      <= x"00000000";
            wbBaseAddressRegister5      <= x"00000000";
        else
            if irdyn = '0' and (clk'event and clk = '0')then
                if ConfigWritePhase = ConfigWrite  and ad /= x"00000000" then
                    case AddressRegister(7 downto 2) is
                        when b"000100"  => wbBaseAddressRegister0   <= ad;
                        when b"000101"  => wbBaseAddressRegister1   <= ad;
                        when b"000110"  => wbBaseAddressRegister2   <= ad;
                        when b"000111"  => wbBaseAddressRegister3   <= ad;
                        when b"001000"  => wbBaseAddressRegister4   <= ad;
                        when b"001001"  => wbBaseAddressRegister5   <= ad;
                        when others     => null;
                    end case;
                else
                    if Memory_WritePhase = Memory_Write or IO_WritePhase = IO_Write then
                        AddressLocalWdb <= ad;
                    else
                        wbBaseAddressRegister0      <= wbBaseAddressRegister0;
                        wbBaseAddressRegister1      <= wbBaseAddressRegister1;
                        wbBaseAddressRegister2      <= wbBaseAddressRegister2;
                        wbBaseAddressRegister3      <= wbBaseAddressRegister3;
                        wbBaseAddressRegister4      <= wbBaseAddressRegister4;
                        wbBaseAddressRegister5      <= wbBaseAddressRegister5;
                        null;
                    end if;
                end if;
            else
                null;
            end if;
        end if;
    end process;

    process(rstn,clk,idsel,cben)
    begin
        if rstn = '0' then
            devseln <= '1';
        else
            if clk'event and clk = '1' then
                case PCI_OperationPhases is
                    when IDLE =>
                        if framen = '0' then
                            if ConfigReadPhase = ConfigRead  or IO_ReadPhase = IO_Read or Memory_ReadPhase = Memory_Read then
                                PCI_OperationPhases <= ReadAccess2;
                            else
                                if ConfigWritePhase = ConfigWrite or IO_WritePhase = IO_Write or Memory_WritePhase = Memory_Write then
                                    PCI_OperationPhases <= WriteAccess2;
                                else
                                    PCI_OperationPhases <= IDLE;
                                end if;
                            end if;
                        end if;

                    when ReadAccess2 =>
                        PCI_OperationPhases     <= ReadAccess3;
                    when ReadAccess3 =>
                        PCI_OperationPhases     <= ReadAccess4;
                        devseln                 <= '0';
                    when ReadAccess4 =>
                        PCI_OperationPhases     <= ReadAccess5;
                    when ReadAccess5 =>
                        PCI_OperationPhases     <= IDLE;
                        devseln                 <= '1';

                    when WriteAccess2 =>
                        PCI_OperationPhases     <= WriteAccess3;
                        devseln                 <= '0';
                    when WriteAccess3 =>
                        PCI_OperationPhases     <= WriteAccess4;
                    when WriteAccess4 =>
                        PCI_OperationPhases     <= WriteAccess5;
                    when WriteAccess5 =>
                        PCI_OperationPhases     <= WriteAccess6;
                    when WriteAccess6 =>
                        PCI_OperationPhases     <= IDLE;
                        devseln                 <= '1';
                    when others => null;
                end case;
            else
                null;
            end if;
        end if;
    end process;

    process(rstn)
    begin
        if rstn = '0' then
            trdyn_status <= '1';
        else
            if PCI_OperationPhases = WriteAccess5 or PCI_OperationPhases = ReadAccess5 then
                if ConfigWritePhase = ConfigWrite or ConfigReadPhase = ConfigRead or Memory_WritePhase = Memory_Write or Memory_ReadPhase = Memory_Read or IO_ReadPhase = IO_Read or IO_WritePhase = IO_Write then
                    trdyn_status<= '0';
                end if;
            else
                trdyn_status <= '1';
            end if;
        end if;
    end process;
    
    process(clk,rstn)
        variable tmp_variable : integer range 0 to 1023;
    begin
        if rstn = '0' then
            null;
        else
            if clk'event and clk = '1' then
                if PCI_OperationPhases >= ReadAccess2 then
                    if ConfigReadPhase = ConfigRead then
                        case AddressRegister(7 downto 2) is
                            when b"000000" => 
                                OutToPciRegister(15 downto 0)                           <= VENDOR_ID;
                                OutToPciRegister(31 downto 16)                          <= DEVICE_ID;
                            when b"000001" => 
                                OutToPciRegister(15 downto 0)                           <= COMMAND;
                                OutToPciRegister(31 downto 16)                          <= STATUS;
                            when b"000010" => 
                                OutToPciRegister(15 downto 0)                           <= REVISION_ID;
                                OutToPciRegister(31 downto 16)                          <= CLASS_CODE;                          
                            when b"000011" => 
                                OutToPciRegister(15 downto 0)                           <= x"4010";
                                OutToPciRegister(31 downto 16)                          <= x"0000";                          
                            when b"0001_00" =>   
                                tmp_variable := BaseAddress0Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress0Size+1)      <= wbBaseAddressRegister0(31 downto BaseAddress0Size+1);
                                    OutToPciRegister(BaseAddress0Size)                  <= '1';
                                    for n in 1 to BaseAddress0Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar0SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                            when b"0001_01" =>   
                                tmp_variable := BaseAddress1Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress1Size+1)      <= wbBaseAddressRegister1(31 downto BaseAddress1Size+1);
                                    OutToPciRegister(BaseAddress1Size)                  <= '1';
                                    for n in 1 to BaseAddress1Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar1SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                            when b"000110" =>   
                                tmp_variable := BaseAddress2Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress2Size+1)      <= wbBaseAddressRegister2(31 downto BaseAddress2Size+1);
                                    OutToPciRegister(BaseAddress2Size)                  <= '1';
                                    for n in 1 to BaseAddress2Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar2SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                            when b"000111" =>
                                tmp_variable := BaseAddress3Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress3Size+1)      <= wbBaseAddressRegister3(31 downto BaseAddress3Size+1);
                                    OutToPciRegister(BaseAddress3Size)                  <= '1';
                                    for n in 1 to BaseAddress3Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar3SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                            when b"001000" =>
                                tmp_variable := BaseAddress4Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress4Size+1)      <= wbBaseAddressRegister4(31 downto BaseAddress4Size+1);
                                    OutToPciRegister(BaseAddress4Size)                  <= '1';
                                    for n in 1 to BaseAddress4Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar4SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                            when b"001001" =>
                                tmp_variable := BaseAddress5Size;
                                if tmp_variable /= 0 then
                                    OutToPciRegister(31 downto BaseAddress5Size+1)      <= wbBaseAddressRegister5(31 downto BaseAddress5Size+1);
                                    OutToPciRegister(BaseAddress5Size)                  <= '1';
                                    for n in 1 to BaseAddress5Size-1 loop
                                        OutToPciRegister(n)                             <= '0';
                                    end loop;
                                    OutToPciRegister(0)                                 <= Bar5SpaceType;
                                else
                                    OutToPciRegister                                    <= x"00000000";
                                end if;
                                
                            when b"001011" => 
                                OutToPciRegister(15 downto 0)                           <= SYS_VENDOR_ID;
                                OutToPciRegister(31 downto 16)                          <= SYS_DEVICE_ID;
                            when b"0011_11" => 
                                OutToPciRegister                                        <= x"0000010f";

                            when b"0011_01" =>
                                OutToPciRegister(15 downto 0)                           <= x"0040";
                                OutToPciRegister(31 downto 16)                          <= x"0000";
                            when b"0100_00" =>
                                OutToPciRegister(15 downto 0)                           <= x"4801";
                                OutToPciRegister(31 downto 16)                          <= x"0001";
                            when b"0100_01" => 
                                OutToPciRegister(15 downto 0)                           <= x"0000";
                                OutToPciRegister(31 downto 16)                          <= x"0000";
                            when b"0100_11" => 
                                OutToPciRegister(15 downto 0)                           <= x"0003";
                                OutToPciRegister(31 downto 16)                          <= x"0000";
                            when b"0101_00" => 
                                OutToPciRegister(15 downto 0)                           <= x"0000";
                                OutToPciRegister(31 downto 16)                          <= x"0000";
                            when b"0100_10" => 
                                OutToPciRegister(15 downto 0)                           <= x"4c06";
                                OutToPciRegister(31 downto 16)                          <= x"0080";
                                
                            when b"0111_00" => 
                                OutToPciRegister(15 downto 0)                           <= x"10b5";
                                OutToPciRegister(31 downto 16)                          <= x"30c2";
                            when b"011101" => 
                                OutToPciRegister(15 downto 0)                           <= REVISION_ID;
                                OutToPciRegister(31 downto 16)                          <= x"0000";
                                
                            when others    => 
                                OutToPciRegister                                        <= x"00000000";
                        end case;
                    else
                        if Memory_ReadPhase = Memory_Read or IO_ReadPhase = IO_Read then
                            if local_cs_status(0) = '0' then
                                case AddressRegister(7 downto 0) is
                                    when x"80"      => OutToPciRegister                 <= DMAMODE0;
                                    when x"a8"      => OutToPciRegister(7 downto 0)     <= DMACRS0;
                                    when others     => null;
                                end case;
                            else        
                                OutToPciRegister(LOCAL_DBUS_WIDE-1 downto 0)                <= local_rdb(LOCAL_DBUS_WIDE-1 downto 0);
                            end if;
                        else
                            null;
                            OutToPciRegister                                            <= x"ZZZZZZZZ";
                        end if;
                    end if;
                else
                    if PCI_OperationPhases = x"0" then
                        OutToPciRegister                                                <= x"00000000";
                    else
                        null;
                    end if;
                end if;
            else
                null;
            end if;
        end if;
    end process;
end;
