﻿SF_INIT:           ;detection et initialisation des contoleur disquette, ATA et USB

;********************************************************************************************************************************
;réinitialise le controleur disquette
mov ax,seldat
mov es,ax
mov ds,ax
mov byte[pos_cyl_disq],0FFh  ;position de la tête indeterminé

mov dx,3F7h ;mode 500000 bit/s
mov al,00h
out dx,al

mov dx,3F2h ;reinitialisation du controleur disquette
mov al,00h
out dx,al


;***********************************************************************************************************************************
;detecte les contolleur ATA sur le bus PCI et enregistre les adresses
mov ebx,80000008h
mov esi,ad_descd
boucle_detec_ata:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je pasctrlata
mov edx,eax
and eax,0FFFF0000h 
cmp eax,001010000h  ;classe=01h sous-classe=01h
jne pasctrlata

mov word[esi+dd_atribut],00h
mov word[esi+dd_atribut+32],10h
mov word[esi+dd_atribut+64],00h
mov word[esi+dd_atribut+96],10h

mov dx,0CF8h
mov eax,ebx
add eax,24     ;BAR4
out dx,eax
mov dx,0CFCh
in eax,dx
test al,1
jz crtl_dma_abs
and eax,0FFFCh
cmp eax,0
je crtl_dma_abs
or word[esi+dd_atribut],08h
or word[esi+dd_atribut+32],08h
or word[esi+dd_atribut+64],08h
or word[esi+dd_atribut+96],08h
crtl_dma_abs:
mov [esi+dd_adress_dma],ax
mov [esi+dd_adress_dma+32],ax
add eax,8
mov [esi+dd_adress_dma+64],ax
mov [esi+dd_adress_dma+96],ax

mov dx,0CF8h
mov eax,ebx
add eax,8     ;BAR0
out dx,eax
mov dx,0CFCh
in eax,dx
test al,1
jz bar0_nok
and eax,0FFFCh
cmp eax,0
jne bar0_ok
bar0_nok:
mov eax,1F0h
bar0_ok:
mov [esi+dd_adress_base],ax
mov [esi+dd_adress_base+32],ax

mov dx,0CF8h
mov eax,ebx
add eax,12     ;BAR1
out dx,eax
mov dx,0CFCh
in eax,dx
test al,1
jz bar1_nok
and eax,0FFFCh
cmp eax,0
jne bar1_ok
bar1_nok:
mov eax,3F6h
bar1_ok:
mov [esi+dd_adress_ctrl],ax
mov [esi+dd_adress_ctrl+32],ax

add esi,64

mov dx,0CF8h
mov eax,ebx
add eax,16     ;BAR2
out dx,eax
mov dx,0CFCh
in eax,dx
test al,1
jz bar2_nok
and eax,0FFFCh
cmp eax,0
jne bar2_ok
bar2_nok:
mov eax,170h
bar2_ok:
mov [esi+dd_adress_base],ax
mov [esi+dd_adress_base+32],ax

mov dx,0CF8h
mov eax,ebx
add eax,20     ;BAR3
out dx,eax
mov dx,0CFCh
in eax,dx
test al,1
jz bar3_nok
and eax,0FFFCh
cmp eax,0
jne bar3_ok
bar3_nok:
mov eax,376h
bar3_ok:
mov [esi+dd_adress_ctrl],ax
mov [esi+dd_adress_ctrl+32],ax

add esi,64
cmp esi,ad_descd+256
je fin_detec_ata

pasctrlata:
add ebx,100h
test ebx,7F000000h
jz boucle_detec_ata


;***************************************************
cmp word[ad_descd+dd_adress_base],0 ;si aucun controleur n'as été detecté, on remplit les descripteur avec les adresses standard
jne fin_detec_ata 

mov ebx,ad_descd
mov ax,1F0h
mov dx,3F6h

boucle_remplissage_ctrl_ata:
mov word[ebx+dd_atribut],00h
mov word[ebx+dd_atribut+32],10h
mov [ebx+dd_adress_base],ax
mov [ebx+dd_adress_base+32],ax
mov [ebx+dd_adress_ctrl],dx
mov [ebx+dd_adress_ctrl+32],dx
mov word[ebx+dd_adress_dma],0
mov word[ebx+dd_adress_dma+32],0

sub ax,80h
sub dx,80h
add ebx,64
cmp ebx,ad_descd+256
jne boucle_remplissage_ctrl_ata


fin_detec_ata:


;*****************************************************************************************************************************
;détecte les controleur ahci

mov ebx,80000008h
boucle_detec_ahci:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
and eax,0FFFFFF00h 
cmp eax,01060100h  ;classe=01h sous-classe=06h  if=01 (AHCI)
jne pas_ctrl_ahci            

ahci_pi equ 00Ch
ahci_port0 equ 100h

ahci_port_commandes equ 00h
ahci_port_rfis equ 08h
ahci_port_int equ 14h

ahci_dev_commandes equ 0
ahci_dev_rfis equ 1024 
ahci_dev_eshost equ 2048
ahci_dev_esport equ 2052
ahci_dev_numport equ 2056
ahci_dev_pci     equ 2060

pushad
;création espace mémoire Host
mov ecx,2000h ;8Ko
mov eax,0FFFh ;??????????????????
call resmemg 
;jc erreur  ;??????????????????

;config Host(pci)
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

;test disponibilité port
mov eax,[ebx+ahci_pi]
mov esi,ebx
add esi,ahci_port0
mov cl,0
boucle_test_port_ahci:
test eax,01h
jz passe_test_port_ahci

;création espace port
push ebx
mov ecx,2000h ;8Ko
mov eax,0FFFh ;??????????????????
call resmemg  
mov edi,ebx
pop ebx
;jc erreur  ;??????????????????

mov [esi+ahci_port_commandes],edi 
add dword[esi+ahci_port_rfis],ahci_dev_commandes  ;lsb command list
mov dword[esi+ahci_port_commandes+4],0            ;msb command list
mov [esi+ahci_port_rfis],edi
add dword[esi+ahci_port_rfis],ahci_dev_rfis ;lsb receved FIS
mov dword[esi+ahci_port_rfis+4],0           ;msb receved FIS
mov dword[esi+ahci_port_int],0 ;interruptions toutes désactivé


;enregistres info dans espace port pour identifier port
mov [edi+ahci_dev_eshost],ebx ;adresse de base E/S du controleur 
mov [edi+ahci_dev_esport],esi ;adresse de base E/S du port
mov [edi+ahci_dev_numport],cl ;numéros de port
;mov [edi+ahci_dev_pci],0 ;adresse PCI   ;??????????????????


;préremplir command list et received FIS
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


;démarrer port
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

passe_test_port_ahci:
inc cl
shr eax,1
add esi,80h
cmp cl,32
jne boucle_test_port_ahci


;activation host
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

popad





pas_ctrl_ahci:
add ebx,100h
test ebx,7F000000h
jz boucle_detec_ahci


;********************************************************************************************************************************
;lit les info disque ata et met a jour les info de partitions
mov ch,10h
mov esi,ad_descd

boucle_init_infopart:
mov al,10
mov edi,bootsecteur
push cx
int 64h          ;charge les info disque
pop cx
cmp eax,0
je init_infodisque_ata


mov al,10
mov edi,bootsecteur
push cx
add ch,8
int 64h          ;si ça ne fonctionne pas on réessaye en ATAPI
pop cx
cmp eax,0
je init_infodisque_atapi


or byte[esi+dd_atribut],7
jmp pasinfopart


init_infodisque_atapi:
or byte[esi+dd_atribut],4
jmp pasinfopart


init_infodisque_ata:
mov eax,[bootsecteur+0C8h]   ;LSB nombre de secteur en LBA48 
mov edx,[bootsecteur+0CCh]   ;MSB nombre de secteur en LBA48 
cmp edx,0
je init_infodisque_lba28
test eax,0C0000000h
jz init_infodisque_lba28
or byte[esi+dd_atribut],3
mov [esi+dd_taille],eax
mov [esi+dd_taille+4],edx
jmp init_infopart

init_infodisque_lba28:
mov eax,[bootsecteur+78h]   ;nombre de secteur en LBA28
cmp eax,0
je init_infodisque_chs
or byte[esi+dd_atribut],2
mov [esi+dd_taille],eax
mov dword[esi+dd_taille+4],0
jmp init_infopart


init_infodisque_chs:
mov eax,[bootsecteur+72h]   ;nombre de secteur en CHS
or byte[esi+dd_atribut],1
mov [esi+dd_taille],eax
mov dword[esi+dd_taille+4],0
push ecx
xor eax,eax
xor ecx,ecx
mov ax,[bootsecteur+70h]   ;secteur par piste
mov cx,[bootsecteur+6Eh]   ;nombre de tête
mov [esi+dd_sec_par_piste],ax
mul ecx
mov [esi+dd_sec_par_cyl],eax       ;nombre de secteur par cylindre
pop ecx


init_infopart:
mov al,12
int 64h


pasinfopart:
inc ch
add esi,32
cmp ch,18h
jne boucle_init_infopart


;*********************************************************************************************************************************************
;code de detection  et de création des descripteur pour les controleur de bus USB 
detection_ctrl_usb:
mov ax,seldat 
mov ds,ax
mov ax,selramh 
mov es,ax
mov ebx,80000008h  ;enable bit + classe code, subclass
mov esi,ad_desc_ctrl_usb
boucletcusb:
mov dx,0CF8h
mov eax,ebx
out dx,eax
mov dx,0CFCh
in eax,dx
cmp ax,0FFFFh
je pasctrl
mov edx,eax
and eax,0FFFF0000h 
cmp eax,0C030000h  ;classe=0Ch sous-classe=03h
jne pasctrl

cmp dh,00h          ;UHCI
je ctrl_uhci
;cmp dh,10h          ;OHCI
;je ctrl_ohci
;cmp dh,20h          ;EHCI
;je ctrl_ehci
;cmp dh,30h          ;XHCI
;je ctrl_xhci
jmp pasctrl

;*************************************
ctrl_uhci:
mov byte[esi+dcu_type],1 ;controleur de type uhci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI

;active controle par e/s
mov dx,0CF8h
mov eax,[esi+dcu_pci]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax

mov dx,0CF8h
mov eax,ebx
add eax,18h ;pour avoir l'adresse de base des ports (BAR4)
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jz pasctrl
and eax,0FFE0h
mov [esi+dcu_es],ax  ;adresse de base du controleur

mov byte[esi+dcu_nb_port],2 ;deux port

push ebx
mov eax,0FFFh
mov ecx,139264   ;136Koctets
mov [esi+dcu_to],ecx
call resmemg 
;§§§§§§§§§§§§§§§§§§§§§§§§que faire en cas d'imposibilité de réserver de la mémoire   
es
mov word[ebx+8],czm_uhci  
add ebx,100010h   ;adresse physique
mov [esi+dcu_mem],ebx
pop ebx 

call init_uhci    ;voir SF_USM.ASM
jmp fin_init_ctrl



;*********************************************
ctrl_ohci:
mov byte[esi+dcu_type],2 ;controleur de type ohci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
call init_ohci    ;voir SF_USM.ASM
jmp fin_init_ctrl


;*************************************************
ctrl_ehci:
mov byte[esi+dcu_type],3 ;controleur de type ehci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI

;active controle par e/s
mov dx,0CF8h
mov eax,[esi+dcu_pci]
add eax,4
out dx,eax
mov dx,0CFCh
mov eax,5   ;command + status register
out dx,eax

mov dx,0CF8h
mov eax,ebx
add eax,8 ;pour avoir l'adresse de base des ports (Bar0)
out dx,eax
mov dx,0CFCh
in eax,dx
test eax,1  ;on vérifie que c'est bien un descripteur de port d'e/s
jnz pasctrl
and eax,0FF00h
mov edx,eax
xor eax,eax
in al,dx
add eax,edx
mov [esi+dcu_es],ax  ;adresse de base du controleur

add dx,4
in eax,dx
and al,0Fh
mov byte[esi+dcu_nb_port],al ;nobre de port (variable)

push ebx
mov eax,0FFFh
mov ecx,1000h   ;4096 octets ;???????????????
call resmemg    
es
mov word[ebx+8],czm_ehci  
add ebx,100010h   ;adresse physique
mov [esi+dcu_mem],ebx
pop ebx 

call init_ehci    ;voir SF_USM.ASM
jmp fin_init_ctrl


;***********************************************
ctrl_xhci:
mov byte[esi+dcu_type],4 ;controleur de type xhci
mov eax,ebx
and eax,0FFFF00h
mov [esi+dcu_pci],eax  ;coordonnée PCI
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
call init_xhci    ;voir SF_USM.ASM



;*****************************
fin_init_ctrl:
add esi,32
pasctrl:
cmp esi,ad_desc_ctrl_usb+800h
je fin_detection_ctrl_usb

add ebx,100h
test ebx,7F000000h
jz boucletcusb
fin_detection_ctrl_usb:


