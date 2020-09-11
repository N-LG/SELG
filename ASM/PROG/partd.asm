﻿partd_asm:
pile equ 4096 ;definition de la taille de la pile
include "fe.inc"
db "logiciel pour le partitionnement des disques"
scode:
org 0
mov eax,8
mov ecx,ZT512C
add ecx,131072
mov dx,sel_dat1
int 61h

mov dx,sel_dat2
mov ah,5   ;option=mode texte+souris
mov al,0   ;création console     
int 63h

mov dx,sel_dat1
mov ds,dx
mov es,dx
mov dx,sel_dat2
mov fs,dx

mov edx,bitpp
mov al,2   ;information video     
int 63h




;*****************************************************
choix_disque:
call raz_ecr

mov edx,msgldp1
mov al,11
mov ah,07h ;couleur
int 63h

mov dword[num_disque],0

;listing des disques présent
mov ch,10h
boucle_ldp:
push ecx
mov al,10
mov edi,ZT512A
int 64h
cmp eax,0
jne suite_ldp


;convertit le nom
mov ebx,ZT512A+36h
boucle_convn:
mov ax,[ebx]
xchg al,ah
mov[ebx],ax
add ebx,2
cmp ebx,ZT512A+5Eh
jne boucle_convn

;affiche le nom
mov edx,ZT512A+36h
mov byte[ZT512A+5Eh],0
mov al,11
mov ah,07h ;couleur
int 63h

mov ecx,[ZT512A+0C8h] ;lba48??????????????????????????????????????????
mov edx,[ZT512A+0CCh]


xor edx,edx
mov ecx,[ZT512A+78h] ;lba28
cmp ecx,0
jne taillelba
xor edx,edx
mov ecx,[ZT512A+72h] ;chs
taillelba:

shr ecx,1
mov edx,taille_part
mov al,102
int 61h

mov edx,taille_part
mov al,11
mov ah,07h ;couleur
int 63h

mov edx,kiloctet
mov al,11
mov ah,07h ;couleur
int 63h

pop ecx
mov ebx,[num_disque]
mov[ebx+table_disque],ch
push ecx
inc dword[num_disque]

suite_ldp:
pop ecx
inc ch
cmp ch,18h
jne boucle_ldp



mov al,13
mov bh,7 ;couleur
mov bl,0
mov cl,1
mov ch,[num_disque]
int 63h

and ebx,0FFh
mov al,[ebx+table_disque]
mov [disque_choisie],al



;charge les info disques
mov al,10
mov ch,[disque_choisie]
mov edi,ZT512A
int 64h
cmp eax,0
jne er_accd



;extrait les données de taille et de structure
mov eax,[ZT512A+0C8h]   ;LSB nombre de secteur en LBA48 
mov edx,[ZT512A+0CCh]   ;MSB nombre de secteur en LBA48 
cmp edx,0
je init_infodisque_lba28
test eax,0C0000000h
jz init_infodisque_lba28

mov [taille_disque],eax
mov [taille_disque+4],edx
jmp charge_infostructure

init_infodisque_lba28:
mov eax,[ZT512A+78h]   ;nombre de secteur en LBA28
cmp eax,0
je init_infodisque_chs

mov [taille_disque],eax
mov dword[taille_disque+4],0
jmp charge_infostructure
 
init_infodisque_chs:
mov eax,[ZT512A+72h]   ;nombre de secteur en CHS
mov [taille_disque],eax
mov dword[taille_disque+4],0



charge_infostructure:
mov dword[nb_sec_piste],63         ;détermination des caractéristiques logique

cmp dword[taille_disque+4],0
jne chs_5
cmp dword[taille_disque],16*63*1024
jb chs_1
cmp dword[taille_disque],32*63*1024
jb chs_2
cmp dword[taille_disque],64*63*1024
jb chs_3
cmp dword[taille_disque],128*63*1024
jb chs_4
jmp chs_5

chs_1:
mov dword[nb_tete],16
mov dword[nb_sec_cylindre],16*63
jmp fin_determ_chs
chs_2:
mov dword[nb_tete],32
mov dword[nb_sec_cylindre],32*63
jmp fin_determ_chs
chs_3:
mov dword[nb_tete],64
mov dword[nb_sec_cylindre],64*63
jmp fin_determ_chs
chs_4:
mov dword[nb_tete],128
mov dword[nb_sec_cylindre],128*63
jmp fin_determ_chs
chs_5:
mov dword[nb_tete],255
mov dword[nb_sec_cylindre],255*63
fin_determ_chs:


;charge le MBR
mov al,8
mov ch,[disque_choisie]
mov cl,1
mov edi,ZT512B
mov ebx,0
int 64h
cmp eax,0
je affiche_part


er_accd:   ;erreur lors de l'accès disque
call raz_ecr
mov edx,msg_eraccd
call affiche_erreur_attend
jmp choix_disque




;********************************************
affiche_part:             ;liste les zones detecté
call raz_ecr
mov dword[num_partition],0

mov ebx,ZT512B+1BEh
;cmp byte[ebx+4],0EEh
;je list_part_gpt

mov edx,msg_mbr
mov al,11
mov ah,07h ;couleur
int 63h

boucle_part_mbr:
cmp byte[ebx+4],0
je suite_part_mbr

inc dword[num_partition]

mov edx,chaine_part_mbr
efface_chaine_part_mbr:
mov byte[edx],20h
inc edx
cmp edx,chaine_part_mbr+50
jne efface_chaine_part_mbr

mov byte[chaine_part_mbr+5],"|"
mov byte[chaine_part_mbr+21],"|"
mov byte[chaine_part_mbr+37],"|"
mov byte[chaine_part_mbr+49],13
mov byte[chaine_part_mbr+50],0

mov cl,[ebx+4]          ;code type
mov edx,chaine_part_mbr
mov al,105
int 61h

mov ecx,[ebx+12]          ;taille
shr ecx,1
mov edx,chaine_part_mbr+7
mov al,102
int 61h

mov ecx,[ebx+8]          ;adresse debut
mov edx,chaine_part_mbr+23
mov al,103
int 61h

mov ecx,[ebx+8]          ;adresse fin
add ecx,[ebx+12]
mov edx,chaine_part_mbr+39
mov al,103
int 61h

mov edx,chaine_part_mbr
ajust_chaine_part_mbr:
cmp byte[edx],0
jne pajust_chaine_part_mbr
mov byte[edx],20h
pajust_chaine_part_mbr:
inc edx
cmp edx,chaine_part_mbr+50
jne ajust_chaine_part_mbr


mov edx,chaine_part_mbr
mov al,11
mov ah,07h ;couleur
int 63h


suite_part_mbr:
add ebx,10h
cmp ebx,ZT512B+1FEh
jne boucle_part_mbr 


choix_action:      ;propose une liste d'action
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,3
int 63h


mov edx,msg_action
mov al,11
mov ah,07h ;couleur
int 63h


mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
add ecx,3
mov ch,12
int 63h

cmp bh,1
je fin_programme

cmp bl,0
je choix_disque
cmp bl,1
je fonction_off;§§§§§§§§§§§§§§§§§
cmp bl,2
je fonction_off;§§§§§§§§§§§§§§§§§
cmp bl,3
je cree_partition_mbr
cmp bl,4
je modif_partition_mbr
cmp bl,5
je format_partition_mbr
cmp bl,6
je sup_partition_mbr
cmp bl,7
je sauv_partition_mbr
cmp bl,8
je charge_partition_mbr
cmp bl,9
je fonction_off;§§§§§§§§§§§§§§§§§
cmp bl,10
je charge_code_mbr
fin_programme:
int 60h

;**********************************************************
cree_partition_mbr:



cmp byte[ZT512B+1C2h],0  
je placevide_cree_partition_mbr
cmp byte[ZT512B+1D2h],0  
je placevide_cree_partition_mbr
cmp byte[ZT512B+1E2h],0  
je placevide_cree_partition_mbr
cmp byte[ZT512B+1F2h],0  
je placevide_cree_partition_mbr


mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_cree_er3   ;message d'eerreur plus de partition de libre
call affiche_erreur_attend
jmp choix_action


placevide_cree_partition_mbr:
mov byte[txt_type],0
mov byte[txt_taille],0
mov byte[txt_adresse],0

;demande les caractéristique de la partition a créer
demande_type:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h
mov edx,msg_cree_type  
mov al,11
mov ah,0Fh ;couleur
int 63h
mov ah,07h
mov edx,txt_type
mov ecx,20
mov al,6
int 63h
mov al,101
mov edx,txt_type
int 61h
mov [bin_type],ecx
cmp ecx,0
je demande_type

demande_taille:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,19
int 63h
mov edx,msg_cree_taille
mov al,11
mov ah,0Fh ;couleur
int 63h
mov ah,07h
mov edx,txt_taille
mov ecx,20
mov al,6
int 63h
mov al,100
mov edx,txt_taille
int 61h
shl ecx,1
mov [bin_taille],ecx
cmp ecx,0
je demande_taille

demande_adresse:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,20
int 63h
mov edx,msg_cree_adresse
mov al,11
mov ah,0Fh ;couleur
int 63h
mov ah,07h
mov edx,txt_adresse
mov ecx,20
mov al,6
int 63h
mov al,101
mov edx,txt_adresse
int 61h
mov [bin_adresse],ecx
cmp ecx,0
je demande_adresse


;verifie que la nouvelle partitoin rentre bien dans le disque
mov eax,[bin_adresse]
xor edx,edx
add eax,[bin_taille]
adc edx,0
cmp edx,[taille_disque+4]
ja partition_rentre_pas
cmp eax,[taille_disque]
jbe ok_rentre_dansledisque 

partition_rentre_pas:
mov edx,msg_cree_er2   ;disque trop petit
call affiche_erreur_attend
jmp choix_action

ok_rentre_dansledisque:

;verifie que la nouvelle partition n'écrase pas une autre 
cmp byte[ZT512B+1C2h],0
je ignore_verif_chevauchement2_part1

mov eax,[bin_adresse]
add eax,[bin_taille]
jc ignore_verif_chevauchement1_part1

cmp eax,[ZT512B+1C6h]
jbe ignore_verif_chevauchement2_part1

ignore_verif_chevauchement1_part1:

mov eax,[ZT512B+1C6h]
add eax,[ZT512B+1CAh]
jc ignore_verif_chevauchement2_part1

cmp eax,[bin_adresse]
ja erreur_chevauchement

ignore_verif_chevauchement2_part1:

cmp byte[ZT512B+1D2h],0
je ignore_verif_chevauchement2_part2

mov eax,[bin_adresse]
add eax,[bin_taille]
jc ignore_verif_chevauchement1_part2

cmp eax,[ZT512B+1D6h]
jbe ignore_verif_chevauchement2_part2

ignore_verif_chevauchement1_part2:

mov eax,[ZT512B+1D6h]
add eax,[ZT512B+1DAh]
jc ignore_verif_chevauchement2_part2

cmp eax,[bin_adresse]
ja erreur_chevauchement

ignore_verif_chevauchement2_part2:

cmp byte[ZT512B+1E2h],0
je ignore_verif_chevauchement2_part3

mov eax,[bin_adresse]
add eax,[bin_taille]
jc ignore_verif_chevauchement1_part3

cmp eax,[ZT512B+1E6h]
jbe ignore_verif_chevauchement2_part3

ignore_verif_chevauchement1_part3:

mov eax,[ZT512B+1E6h]
add eax,[ZT512B+1EAh]
jc ignore_verif_chevauchement2_part3

cmp eax,[bin_adresse]
ja erreur_chevauchement

ignore_verif_chevauchement2_part3:

cmp byte[ZT512B+1F2h],0
je ignore_verif_chevauchement2_part4

mov eax,[bin_adresse]
add eax,[bin_taille]
jc ignore_verif_chevauchement1_part4

cmp eax,[ZT512B+1F6h]
jbe ignore_verif_chevauchement2_part4

ignore_verif_chevauchement1_part4:

mov eax,[ZT512B+1F6h]
add eax,[ZT512B+1FAh]
jc ignore_verif_chevauchement2_part4

cmp eax,[bin_adresse]
ja erreur_chevauchement

ignore_verif_chevauchement2_part4:


;enregistre la partiton
mov ebx,ZT512B+1BEh

boucle_placelibre:
cmp byte[ebx+4],0
je placelibre_trouve
add ebx,16
cmp ebx,ZT512B+1FEh
jne boucle_placelibre


mov edx,msg_cree_er3   ;pas de partition de libre!
call affiche_erreur_attend
jmp choix_action


;enregistre les données de la partition
placelibre_trouve:
mov byte[ebx],0

mov eax,[bin_adresse]
xor edx,edx
mov ecx,[nb_sec_cylindre]
div ecx
push eax   
mov eax,edx
xor edx,edx
mov ecx,[nb_sec_piste] ;nb de secteur par piste
div ecx  ;eax=tête
pop ecx  ;ecx=cylindre  
inc edx  ;edx=secteur

test eax,0FFFFFF00h  ;corrige les valeur si ça dépasse le maximum
jz pas_aj_tete1
mov eax,0FFh
pas_aj_tete1:
test ecx,0FFFFFC00h
jz pas_aj_cyl1
mov ecx,3FFh
pas_aj_cyl1:
test edx,0FFFFFFC0h
jz pas_aj_sect1
mov edx,03Fh
pas_aj_sect1:

shl ch,6
or ch,dl
mov byte[ebx+1],al ;tête du premier secteur
mov word[ebx+2],cx ;cylindre/secteur du premier secteur

mov al,[bin_type]
mov [ebx+4],al

mov eax,[bin_adresse]
add eax,[bin_taille]
dec eax
xor edx,edx

mov ecx,[nb_sec_cylindre]
div ecx
push eax   
mov eax,edx
xor edx,edx
mov ecx,[nb_sec_piste] ;nb de secteur par piste
div ecx  ;eax=tête
pop ecx  ;ecx=cylindre  
inc edx  ;edx=secteur

test eax,0FFFFFF00h  ;corrige les valeur si ça dépasse le maximum
jz pas_aj_tete2
mov eax,0FFh
pas_aj_tete2:
test ecx,0FFFFFC00h
jz pas_aj_cyl2
mov ecx,3FFh
pas_aj_cyl2:
test edx,0FFFFFFC0h
jz pas_aj_sect2
mov edx,03Fh
pas_aj_sect2:

shl ch,6
and ch,0C0h
and edx,03Fh
or ch,dl
mov byte[ebx+5],al ;tête du dernier secteur
mov word[ebx+6],cx ;cylindre/secteur du dernier secteur

mov edx,[bin_adresse]
mov ecx,[bin_taille]
mov [ebx+8],edx
mov [ebx+12],ecx




;remet dans l'ordre les partitons
mov esi,ZT512B+1BEh
mov edi,ZT512B+1CEh
call trie_adresse
mov edi,ZT512B+1DEh
call trie_adresse
mov edi,ZT512B+1EEh
call trie_adresse
mov esi,ZT512B+1CEh
mov edi,ZT512B+1DEh
call trie_adresse
mov edi,ZT512B+1EEh
call trie_adresse
mov esi,ZT512B+1DEh
mov edi,ZT512B+1EEh
call trie_adresse
jmp sauvegarde_mbr


;**************
trie_adresse:
cmp byte[esi+4],0
je fin_trie_adresse
cmp byte[edi+4],0
je fin_trie_adresse

mov eax,[esi+8]
cmp [edi+8],eax
ja fin_trie_adresse

;echange les descripteurs
mov eax,[esi]
mov edx,[edi]
mov [edi],eax
mov [esi],edx
mov eax,[esi+4]
mov edx,[edi+4]
mov [edi+4],eax
mov [esi+4],edx
mov eax,[esi+8]
mov edx,[edi+8]
mov [edi+8],eax
mov [esi+8],edx
mov eax,[esi+12]
mov edx,[edi+12]
mov [edi+12],eax
mov [esi+12],edx

fin_trie_adresse:
ret

;***********
erreur_chevauchement:
mov edx,msg_cree_er1   ;place déja occupé
call affiche_erreur_attend
jmp choix_action




;*******************************************************************************************************
modif_partition_mbr:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,12
int 63h

mov edx,msg_modif1
mov al,11
mov ah,0Fh ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
shl ecx,8
mov cl,2
int 63h

cmp bh,1
je affiche_part

;£££££££££££££££££££££££££££££££££££££££££££££££££££££££$
jmp sauvegarde_mbr




;************************************************************
format_partition_mbr:
mov al,12
mov ebx,0
mov ecx,[resyt]
dec ecx
int 63h

mov edx,msg_format1
mov al,11
mov ah,0Fh ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
shl ecx,8
mov cl,2
int 63h

cmp bh,1
je affiche_part

;charge les données spécifique a la partition
and ebx,03h
shl ebx,4
add ebx,ZT512B+1C6h
mov eax,[ebx]
mov edx,[ebx+4]
mov [format_offset_partition],eax
mov [format_taille_totale],edx

call raz_ecr
mov edx,msg_format2
mov al,11
mov ah,07h ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov cl,0
mov ch,5
int 63h

cmp bh,1
je affiche_part
cmp bl,1
je format_partition_fat16r_mbr
cmp bl,2
je format_partition_fat16c_mbr
cmp bl,3
je format_partition_fat32r_mbr
cmp bl,4
je format_partition_fat32c_mbr
jmp affiche_part


;**********************************
format_partition_fat16r_mbr:
mov byte[format_type],'r'
jmp format_partition_fat16_mbr

format_partition_fat16c_mbr:
mov byte[format_type],'c'


format_partition_fat16_mbr: ;charge les variables spécifique au FAT16
mov dword[format_taille_reserve],64        ;secteurs réservé (secteur de boot+secteur après+répertoire racine fat16) 
mov dword[format_cluster_par_secteur_fat],256  ;cluster par secteur de fat 
mov dword[format_nombre_max_cluster],0FFEEh    ;nombre max de cluster  
jmp formattage_fat


;**********************************
format_partition_fat32r_mbr:
mov byte[format_type],'R'
jmp format_partition_fat32_mbr

format_partition_fat32c_mbr:
mov byte[format_type],'C'

format_partition_fat32_mbr:  ;charge les variables spécifique au FAT32
mov dword[format_taille_reserve],32          ;secteurs réservé (secteur de boot+secteur après)  
mov dword[format_cluster_par_secteur_fat],128  ;cluster par secteur de fat 
mov dword[format_nombre_max_cluster],0FFFFFEEh ;nombre max de cluster 


;**********************************
formattage_fat:

;demande choix nombre de table FAT
mov edx,msg_format3
mov al,11
mov ah,07h ;couleur
int 63h

mov word[saisienum],50
mov ah,07h
mov edx,saisienum
mov ecx,12
mov al,6
int 63h

mov al,100
mov edx,saisienum
int 61h

cmp ecx,2
jb nok_nombre_fat
cmp ecx,8
jbe ok_nombre_fat

nok_nombre_fat:
mov edx,msg_format4
mov al,11
mov ah,0Ch ;couleur
int 63h
jmp formattage_fat

ok_nombre_fat:


;détermine la taille utilisable par les fat et les clusters
mov eax,[format_taille_totale]
sub eax,[format_taille_reserve]
mov [format_taille_utile],eax


;determine taille minimum d'un cluster en fonction du nombre maximum et du nombre de fat souhaité
mov eax,[format_nombre_max_cluster]
mov ecx,[format_nombre_fat]
xor edx,edx
mul ecx
mov ecx,[format_cluster_par_secteur_fat]
div ecx
cmp edx,0
je ok1
inc eax
ok1:
mov ecx,[format_taille_utile]
sub ecx,eax
mov eax,ecx
mov ecx,[format_nombre_max_cluster]
xor edx,edx
div ecx
cmp edx,0
je ok2
inc eax
ok2: ;eax=nombre de secteur minimum par cluster

;détermine la taille de cluster en fonction de la taille minimum
mov ecx,1
boucle3:
cmp ecx,eax
jae ok3
shl cl,1
inc ch
jmp boucle3
ok3:     ;cl=taille_cluster ch=decalage
mov [format_taille_cluster],cl

;determine nombre réel de cluster en fonction de la taille cluster
mov eax,[format_cluster_par_secteur_fat]
xor edx,edx
mul ecx
inc eax
mov ecx,eax  ;ecx=taille occupé par autant de cluster qu'il y en as dans un secteur de fat
mov eax,[format_taille_utile]
xor edx,edx
div ecx  ;eax=nombre de secteur par fat
mov [format_taille_fat],eax
xor edx,edx
mov ecx,[format_cluster_par_secteur_fat]
mul ecx   ;eax=nombre de cluster
mov [format_nb_cluster],eax


;efface les données demandé
mov ebx,ZT512C
boucle_effacezt:
mov dword[ebx],0
add ebx,4
cmp ebx,ZT512C+8192
jne boucle_effacezt



cmp byte[format_type],'R'
je effacement_rapide
cmp byte[format_type],'r'
je effacement_rapide

;effacement total de la partition
mov ebx,[format_offset_partition]
mov ecx,[format_taille_totale]
mov edi,ecx
jmp boucle_effacedata

effacement_rapide:
mov ebx,[format_offset_partition]

mov eax,[format_taille_fat]
mov ecx,[format_nombre_fat]
xor edx,edx
mul ecx
mov ecx,[format_taille_reserve]
add ecx,[format_cluster_par_secteur_fat]
add ecx,eax    ;dernier secteur a effacer+1
mov edi,ecx

boucle_effacedata:
cmp ecx,256
jbe fin_effacedata
push ebx
push ecx
push edx
mov al,9
mov ch,[disque_choisie]
mov cl,0
mov esi,ZT512C
int 64h
pop edx
pop ecx
pop ebx
cmp eax,0
jne erreur_ecriture_formattage
add ebx,256
sub ecx,256

;affiche une barre de progression
push ebx
push ecx
push edx
mov esi,edi ;edi=total
sub esi,ecx  ;esi=index
mov ebx,0   ;position en x du début de la barre de progression
mov ecx,[resyt] 
sub ecx,3   ;position en y du début de la barre de progression
mov edx,[resxt] ;longueur de la barre de progression
mov al,14
int 63h
pop edx
pop ecx
pop ebx
jmp boucle_effacedata



fin_effacedata:
mov al,9
mov ch,[disque_choisie]
mov esi,ZT512C
int 64h
cmp eax,0
jne erreur_ecriture_formattage


cmp byte[format_type],'R'
je formattage_fat32
cmp byte[format_type],'C'
je formattage_fat32


;*******************************
;charge les données de base des tables FAT16
mov dword[ZT512C],0FFFFFFF8h ;marque les deux premier cluster comme une fin de fichier car ils n'existent pas
xor eax,eax
mov ebx,[format_offset_partition]
mov ax,[secteur_reserve_fat16]
add ebx,eax
mov ecx,[format_nombre_fat]


boucle_init_fat16:
push ebx
push ecx
mov al,9
mov ch,[disque_choisie]
mov cl,1
mov esi,ZT512C
int 64h
pop ecx
pop ebx
add ebx,[format_taille_fat]
dec ecx
jnz boucle_init_fat16



;*************************************
;prépare le secteur de boot FAT16
mov eax,[format_taille_cluster]
mov byte[secteur_par_cluster_fat16],al

mov ecx,[format_nombre_fat]
mov byte[nb_fat_fat16],cl

mov eax,[format_taille_fat]
mov word[taille_fat_16b_fat16],ax

mov ax,[nb_sec_piste]
mov word[nb_sect_par_piste_fat16],0 
mov ax,[nb_tete]
mov word[nb_tete_fat16],ax          

mov eax,[format_offset_partition]
mov dword[adresse_premier_secteur_fat16],eax
mov eax,[format_taille_totale]
test eax,0FFFF0000h
jz fat16_taille16b

mov word[nb_secteur_16b_fat16],0
mov dword[nb_sect_32b_fat16],eax
jmp fat16_fintaille

fat16_taille16b:
mov word[nb_secteur_16b_fat16],ax
mov dword[nb_sect_32b_fat16],0

fat16_fintaille:
mov eax,12
int 61h
mov edx,eax
shl eax,16
xor eax,edx          ;génère un "numéros de série" a partir du compteur temp
xor eax,[ZT512A+20] ;et du numéros de série disque
mov dword[num_serie_fat16],eax


;charge le secteur de boot FAT16
mov al,9
mov ebx,[format_offset_partition]
mov ch,[disque_choisie]
mov cl,1
mov esi,secteur_fat16
int 64h
cmp eax,0
jne erreur_ecriture_formattage
jmp affiche_part 



;*******************************
formattage_fat32:
;charge les données de base des tables FAT32
mov dword[ZT512C],0FFFFFFF8h   ;marque le premier cluster comme une fin de fichier car il n'existe pas
mov dword[ZT512C+4],0FFFFFFF8h ;marque le deuxième cluster comme une fin de fichier car il n'existent pas
mov dword[ZT512C+8],0FFFFFFF8h ;marque le troisième cluster comme une fin de fichier car c'est le cluster de départ du repertoire racine
xor eax,eax
mov ebx,[format_offset_partition]
mov ax,[secteur_reserve_fat32]
add ebx,eax
mov ecx,[format_nombre_fat]

boucle_init_fat32:
push ebx
push ecx
mov al,9
mov ch,[disque_choisie]
mov cl,1
mov esi,ZT512C
int 64h
pop ecx
pop ebx
add ebx,[format_taille_fat]
dec ecx
jnz boucle_init_fat32


;*************************************
;prépare le secteur de boot FAT32
mov eax,[format_taille_cluster]
mov byte[secteur_par_cluster_fat32],al

mov ecx,[format_nombre_fat]
mov byte[nb_fat_fat32],cl

mov eax,[format_taille_fat]
mov dword[taille_fat_32b_fat32],eax

mov ax,[nb_sec_piste]
mov word[nb_sect_par_piste_fat32],0 
mov ax,[nb_tete]
mov word[nb_tete_fat32],ax          

mov eax,[format_offset_partition]
mov dword[adresse_premier_secteur_fat32],eax
mov eax,[format_taille_totale]
test eax,0FFFF0000h
jz fat32_taille16b

mov word[nb_secteur_16b_fat32],0
mov dword[nb_sect_32b_fat32],eax
jmp fat32_fintaille

fat32_taille16b:
mov word[nb_secteur_16b_fat32],ax
mov dword[nb_sect_32b_fat32],0

fat32_fintaille:
mov eax,12
int 61h
mov edx,eax
shl eax,16
xor eax,edx          ;génère un "numéros de série" a partir du compteur temp
xor eax,[ZT512A+20] ;et du numéros de série disque
mov dword[num_serie_fat32],eax


;charge le secteur de boot FAT32
mov al,9
mov ebx,[format_offset_partition]
mov ch,[disque_choisie]
mov cl,1
mov esi,secteur_fat32
int 64h
cmp eax,0
jne erreur_ecriture_formattage

;charge la copie du secteur de boot
mov al,9
mov ebx,[format_offset_partition]
add ebx,31
mov ch,[disque_choisie]
mov cl,1
mov esi,secteur_fat32
int 64h
cmp eax,0
je affiche_part


;******************************
erreur_ecriture_formattage:
mov edx,msg_format_er1
call affiche_erreur_attend
jmp affiche_part


;************************************************************************************************
sup_partition_mbr:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,12
int 63h

mov edx,msg_sup1
mov al,11
mov ah,0Fh ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
shl ecx,8
mov cl,2
int 63h

cmp bh,1
je affiche_part

and ebx,03h
shl ebx,4
add ebx,ZT512B+1BEh

cmp ebx,ZT512B+1EEh  ;sauf si on souhaite décaler le dernier descripteur, on décale les partitions
je pasdecal 
mov esi,ebx
mov edi,ebx
mov ecx,ZT512B+1EEh
add esi,10h
sub ecx,ebx
cld
rep movsb
pasdecal:

mov dword[ZT512B+1EEh],0    ;efface le dernier descripteur
mov dword[ZT512B+1F2h],0
mov dword[ZT512B+1F6h],0
mov dword[ZT512B+1FAh],0
jmp sauvegarde_mbr




;***********************************************************
sauv_partition_mbr:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_sauvp1
mov al,11
mov ah,0Fh ;couleur
int 63h

mov edx,nom_fichier
mov ecx,256
mov al,6
mov ah,0Fh   ;couleur
int 63h

;ouvre le fichier
mov al,0
mov edx,nom_fichier
mov ebx,0
int 64h
cmp eax,0
jne sauv_partition_mbr    ;si on arrive pas a ouvrir on redemande le nom
mov [handle],ebx


;fixe la taille a zéro
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_sauvp2
mov al,11
mov ah,0Fh ;couleur
int 63h
mov edx,msg_blanc
mov al,11
mov ah,0Fh ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
shl ecx,8
mov cl,2
int 63h

;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp affiche_part


;************************************************************
charge_partition_mbr:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_chargp1
mov al,11
mov ah,0Fh ;couleur
int 63h

mov edx,nom_fichier
mov ecx,256
mov al,6
mov ah,0Fh   ;couleur
int 63h

;ouvre le fichier
mov al,0
mov edx,nom_fichier
mov ebx,0
int 64h
cmp eax,0
jne charge_partition_mbr    ;si on arrive pas a ouvrir on redemande le nom
mov [handle],ebx

;test la taille du fichier
mov al,6
mov ah,1 ;taille
mov ebx,[handle]
mov edx,taille_fichier
int 64h
cmp eax,0
jne charge_partition_mbr    ;si on arrive pas a lire la taille, on redemande le nom


mov eax,[taille_fichier]
add eax,511
shr eax,9
mov [taille_fichier],eax

mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_chargp2
mov al,11
mov ah,0Fh ;couleur
int 63h
mov edx,msg_blanc
mov al,11
mov ah,0Fh ;couleur
int 63h


mov al,13
mov bh,7 ;couleur
mov bl,0
mov ecx,[num_partition]
shl ecx,8
mov cl,2
int 63h

cmp bh,1
je affiche_part

and ebx,03h
shl ebx,4
add ebx,ZT512B+1BEh
mov eax,[ebx+8]


mov ecx,[ebx+12]
cmp ecx,[taille_fichier]
jb part_plus_petit 
mov ecx,[taille_fichier]
part_plus_petit:
xor edx,edx
mov ebx,eax

boucle_charge_partition_mbr:


push ebx
push ecx
push edx
mov al,4
mov ecx,512
mov edi,ZT512A
mov ebx,[handle]
int 64h
pop edx
pop ecx
pop ebx
cmp eax,0
jne erreur_chargementpart

push ebx
push ecx
push edx
mov al,9
mov ch,[disque_choisie]
mov cl,1
mov esi,ZT512A
int 64h
pop edx
pop ecx
pop ebx
cmp eax,0
jne erreur_chargementpart




add edx,512
inc ebx
dec ecx
jnz boucle_charge_partition_mbr



jmp affiche_part




erreur_chargementpart:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
jmp choix_action







;********************************************************
charge_code_mbr:
mov al,12
mov ebx,0
mov ecx,[num_partition]
add ecx,18
int 63h

mov edx,msg_code1 
mov al,11
mov ah,0Fh ;couleur
int 63h

mov edx,nom_fichier
mov ecx,256
mov al,6
mov ah,0Fh   ;couleur
int 63h

;ouvre le fichier
mov al,0
mov edx,nom_fichier
mov ebx,0
int 64h
cmp eax,0
jne charge_code_mbr    ;si on arrive pas a ouvrir on redemande le nom
mov [handle],ebx



;test la taille du fichier
mov al,6
mov ah,1 ;taille
mov ebx,[handle]
mov edx,taille_fichier
int 64h
cmp eax,0
jne charge_code_mbr    ;si on arrive pas a lire la taille, on redemande le nom


;si superieur a l'espace propose plusieur solution

cmp dword[taille_fichier+4],0
jne erreur_taille_code
mov ecx,[taille_fichier]
cmp ecx,440
jbe charge_code

erreur_taille_code:
call raz_ecr

mov edx,msg_code2  
mov al,11
mov ah,0Fh ;couleur
int 63h

mov al,13
mov bh,7 ;couleur
mov bl,0
mov ch,1
mov cl,3
int 63h

cmp bl,0
je affiche_part
cmp bl,1
je charge_code_limite


charge_code_complet:
mov ecx,510
jmp charge_code

charge_code_limite:   
mov ecx,440
charge_code:
mov al,4
xor edx,edx
mov edi,ZT512B
mov ebx,[handle]
int 64h
cmp eax,0
;jne XXXXXXXXXXXXXXXXx

;place l'indication de code executable
mov word[ZT512B+1FEh],0AA55h

sauvegarde_mbr:              ;sauvegarde le mbr
mov al,9
mov ch,[disque_choisie]
mov cl,1
mov esi,ZT512B
mov ebx,0
int 64h
cmp eax,0
;jne XXXXXXXXXXXXXXXXx


mov al,12                  ;signal au systeme qu'il doit réactualiser sa liste
mov ch,[disque_choisie]
int 64h

jmp affiche_part









;***********************************************************
fonction_off:


mov edx,msg_fonction_off ;message en attendant 
call affiche_erreur_attend
call raz_ecr
jmp affiche_part



;sous fonctions****************************************************************************


raz_ecr:
fs
mov ebx,[ad_texte]
fs
mov ecx,[to_texte]
shr ecx,2

boucle_raz_ecr:
fs
mov dword[ebx],0
add ebx,4
dec ecx
jnz boucle_raz_ecr


xor ebx,ebx
xor ecx,ecx
mov al,12
int 63h     ;place le curseur en 0.0
ret




;***************************
affiche_erreur_attend:
mov ebx,0
mov ecx,[resyt] 
sub ecx,2 
mov al,10
mov ah,0Ch ;couleur
int 63h

mov edx,msg_attend
mov ebx,0
mov ecx,[resyt] 
dec ecx 
mov al,10
mov ah,07h ;couleur
int 63h

boucle_affiche_erreur_attend:
mov al,5
int 63h
cmp al,0
je boucle_affiche_erreur_attend
ret

















;**************************************************************************************
sdata1:
org 0

msgldp1:
db "choisisez le disque:",13,0

kiloctet:
db "Kilo-octets",13,0


msg_eraccd:
db "erreur lors de l'accèes au disque, voulez vous?",13
db "réessayer",13
db "choisir un autre disque?",0

msg_vide:
db "aucune structure n'as été detecté",13,0


msg_mbr:
db "structure actuelle du disque (partitionnement MBR)",13
db "type | taille (Ko)   | adresse debut | adresse fin ",13,0

chaine_part_mbr:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

msg_gpt:
db "structure actuelle du disque (partitionnement GPT)",13
db "GUID             |  taille (Mo)  | adresse debut    ",13,0





msg_chargp1:
db "selectionnez le fichier a charger:",0
msg_chargp2:
db "selectionnez la partition a charger",0


msg_sauvp1:
db "selectionnez le fichier ou sauvegarder:",0
msg_sauvp2:
db "selectionnez la partition a sauvegarder",0



msg_action:
db "choisir un autre disque",13
db "sauvegarder une image du disque",13
db "charger une image dans le disque",13
db "créer une partition",13
db "modifier type de partition",13
db "formatter une partition",13
db "supprimer une partition",13
db "sauvegarder une image de partition",13
db "charger une image dans la partition",13
db "changer le mode de partitionnement",13
db "changer le programe d'amorçage",13
db "quitter",13,0


msg_cree_type:
db "code du type de partition:",0
msg_cree_taille:
db "taille de la partition (Ko):",0
msg_cree_adresse:
db "adresse du premier secteur:",0

txt_taille:
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
txt_adresse:
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
txt_type:
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
bin_type:
dd 0
bin_taille:
dd 0
bin_adresse:
dd 0




msg_cree_er1:
db "impossible de créer la partition, l'espace souhaité est déja occupée",0
msg_cree_er2:
db "impossible de créer la partition, car elle s'étend au dela de la capacité du disque",0
msg_cree_er3:
db "impossible de créer la partition, il n'y as plus de partition de libre",0



msg_blanc:
db "                                                                                ",0


msg_modif1:
db "choisissez la partition a modifier (echap pour annuler)",0
 
msg_format1:
db "choisissez la partition a formatter (echap pour annuler)",0


msg_format2:
db "ne pas Formatter le disque",13
db "Formattage rapide en FAT16(sans effacement contenu Cluster)",13
db "Formattage complet en FAT16(avec effacement contenu Cluster)",13
db "Formattage rapide en FAT32(sans effacement contenu Cluster)",13
db "Formattage complet en FAT32(avec effacement contenu Cluster)",13,13,0

msg_format3:
db "combien de table FAT enregistré sur le disque? (2 à 8)",13,0
msg_format4:
db "valeur incorrecte, veuillez saisir un valeur dans les tolérance pour poursuivre (echap pour annuler)",13,0

msg_format_er1:
db "erreur lors de l'écriture sur le disque",0

msg_sup1:
db "choisissez la partition a supprimer (echap pour annuler)",0
msg_sup2:
db "êtes vous CERTAIN de vouloir supprimer cette partition? (O/N)",0


msg_mode1:
db "pour l'instant, le mode de partitionnement des bios UEFI n'est hélas pas supporté                 ",0


msg_code1:
db "veuillez spécifier le nom du fichier contenant le code d'amorçage que vous souhaitez installer:",0
msg_code2:
db "le fichier choisie est plus grand que l'espace du MBR prévu a cet effet, voulez vous?",13 
db "ne rien faire",13
db "remplacer uniquement le code",13
db "remplacer tout le contenue du secteur(et ecraser la table de partition)",0


msg_fonction_off:
db "cette fonction n'est pas encore active",0

msg_attend:
db "appuyez sur une touche pour continuer...",0

saisienum:
dd 0,0,0,0


taille_part:
dd 0,0,0,0,0,0,0,0


taille_disque:
dd 0,0

num_disque:
dd 0


nb_sec_piste:
dd 0
nb_tete:
dd 0
nb_sec_cylindre:
dd 0  

num_partition:
dd 0

table_disque:
dd 0,0,0,0

handle:
dd 0
taille_fichier:
dd 0,0


disque_choisie:
db 0


bitpp:   ;structure d'info pour le mode video en cours
dd 0
resx:
dd 0
resy:
dd 0
resxt:
dd 0
resyt:
dd 0
xs1:
dd 0
ys1:
dd 0
xs2:
dd 0
ys2:
dd 0
octpl:
dd 0



;*************************************
format_type:
db 0

;données partition
format_taille_totale:          ;taille totale
dd 0
format_offset_partition:
dd 0

;donnée spécifique suivant type de partition
format_taille_reserve:          ;secteurs réservé (secteur de boot+secteur après+répertoire racine fat16)
dd 0        
format_cluster_par_secteur_fat:       ;cluster par secteur de fat
dd 128     
format_nombre_max_cluster:        ;nombre max de cluster
dd 656557   

format_nombre_fat:
dd 2
format_taille_utile:
dd 0
format_taille_cluster:
db 0
format_nb_cluster:
db 0
format_taille_fat:
dd 0



;*************************************
secteur_fat16:
use16
jmp code_fat16 
nop
nom_prog_formattage_fat16:
db "PARTD.FE"
octet_par_secteur_fat16:
dw 512
secteur_par_cluster_fat16:
db 0
secteur_reserve_fat16:
dw 32
nb_fat_fat16:
db 0
taille_rep_racine_fat16:
dw 512
nb_secteur_16b_fat16:
dw 0
type_fat16:
db 0F8h
taille_fat_16b_fat16:
dw 0
nb_sect_par_piste_fat16:
dw 0
nb_tete_fat16:
dw 0
adresse_premier_secteur_fat16:
dd 0
nb_sect_32b_fat16:
dd 0
id_fat16:
db 80h
reserve_fat16:
db 0
signature_fat16:
db 29h
num_serie_fat16:
dd 0
nom_fat16:
db "NO NAME    "
nom_type_fat16:
db "FAT16   "
code_fat16:


stra:               ;62
db "fichier SYST.BAZ absent"
strb:
mov ax,7C0h
mov ds,ax

mov ax,2000h             ;charge une FAT en 2000h:0000
mov es,ax
xor si,si
mov bp,[taille_fat_16b_fat16]
mov bx,1

bchf:
call chcl
dec bp
inc bx
add si,200h
cmp bp,0
jne bchf

mov ax,3000h             ;charge repertoire racine en 3000h:0000
mov es,ax
xor si,si
mov bp,[taille_rep_racine_fat16]
mov ax,[taille_fat_16b_fat16]
mov cl,[nb_fat_fat16]
mul cl
inc ax
mov bx,ax

bchd:
call chcl
sub bp,16
inc bx
add si,200h
cmp bp,0
jne bchd

;*****************************************
mov cx,[taille_rep_racine_fat16]
xor bx,bx
testp:
xor di,di
boucp:
mov al,[43+di]
es
mov ah,[bx+di]
cmp al,ah
jne rate
inc di
cmp di,11
je fin
jmp boucp

rate:
add bx,32
dec cx
cmp cx,0
je stop
jmp testp

stop:
mov cx,23
mov si,62
call afmg
nopp:
nop
jmp nopp

fin:
es
mov ax,[bx+26]
mov bx,ax
;*****************************************    

mov ax,5000h            ;charge le fichier en 5000h:0000h
mov es,ax
xor si,si

mov bp,[taille_rep_racine_fat16]
shr bp,4
mov ax,[taille_fat_16b_fat16]
mov cl,[nb_fat_fat16]
mul cl
dec ax
add ax,bp

bocharg:
add bx,ax
call chcl
sub bx,ax
call chnb
cmp bx,0FF0h
jge sauverfic
add si,200h
jmp bocharg

sauverfic:         
mov ax,5000h        ;chargement des segment
mov ds,ax
mov es,ax
mov ax,9000h        
;mov ss,ax
;xor ax,ax           ;remise a zero des registre    
;xor bx,bx
;xor cx,cx
;xor dx,dx
;xor si,si
;xor di,di
;xor bp,bp
;xor sp,sp            ;reinitialisation de la pile
jmp 5000h:0000h


chnb:                 ;charge nø de FAT
push ax               ;entr‚e: bx=Nøde FAT
push cx               ;Sortie bx=Nøcontenue dans la FAT
push dx
push es

mov ax,2000h
mov es,ax
shr bx,1
jc  unns
mov ax,bx
mov cl,3
mul cl
mov bx,ax
es
mov ax,[bx]
mov bx,ax
and bx,0FFFh
jmp kirk
unns:
mov ax,bx
mov cl,3
mul cl
mov bx,ax
inc bx
es
mov ax,[bx]
mov bx,ax
shr bx,4
and bx,0FFFh
kirk:
pop es
pop dx
pop cx
pop ax
ret


chcl:    ;bx=Nøcluster es:si=zone ou copier
push ax
push bx
push cx
push dx
push bp
push si
mov cx,[nb_sect_par_piste_fat16] 
mov ax,[26] 
mul cx
mov cx,ax
mov ax,bx
xor dx,dx
div cx
mov bx,ax
mov ax,dx
mov cl,[24]
div cl
mov dh,al
mov cx,bx
xchg cl,ch
shl cl,6
and cl,0C0h
inc ah
and ah,03Fh
or cl,ah
mov bp,5
mov bx,si
alfq: 
mov al,1
mov ah,2
xor dl,dl
int 13h
jnc findec
dec bp
jnz alfq
findec:
pop si
pop bp
pop dx
pop cx
pop bx
pop ax
ret

afmg:          ;affiche message en ds:si    cx=nb  carac
push ax
push bx
push si

mov ah,0Eh
mov bl,0Ah
bome:
mov al,[si]
int 10h
inc si
dec cx
jnz bome
pop si
pop bx
pop ax
ret
















rb 510 + secteur_fat16 - $ 
db 055h,0AAh


;***********************
secteur_fat32:
jmp code_fat32
nop
nom_prog_formattage_fat32:
db "PARTD.FE"
octet_par_secteur_fat32:
dw 512
secteur_par_cluster_fat32:
db 0
secteur_reserve_fat32:
dw 32
nb_fat_fat32:
db 0
taille_rep_racine_fat32:
dw 0
nb_secteur_16b_fat32:
dw 0
type_fat32:
db 0F8h
taille_fat_16b_fat32:
dw 0
nb_sect_par_piste_fat32:
dw 0
nb_tete_fat32:
dw 0
adresse_premier_secteur_fat32:
dd 0
nb_sect_32b_fat32:
dd 0
taille_fat_32b_fat32:
dd 0
attribut_fat32:
dw 0
version_fat32:
db 0,0
racine_fat32:
dd 2
info_supplémentaire_fat32:
dw 1
secteur_copie_boot_fat32:
dw 31
reserve_fat32:
dd 0,0,0
id_fat32:
db 80h
réserve2_fat32:
db 0
signature_fat32:
db 29h
num_serie_fat32:
dd 0
nom_fat32:
db "NO NAME    "
nom_type_fat32:
db "FAT32   "
code_fat32:
;§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
rb 510 + secteur_fat32 - $ 
db 055h,0AAh





nom_fichier:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


ZT512A:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

ZT512B:
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;64
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

ZT512C:


sdata2:
org 0
;données du segment ES
sdata3:
org 0
;données du segment FS
sdata4:
org 0
;données du segment GS
findata: