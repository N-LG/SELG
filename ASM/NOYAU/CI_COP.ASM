nom_entree equ 0
nom_sortie equ 512
handle_entree equ 1024
handle_sortie equ 1028
taille_entree equ 1032
offset_transfert equ 1036
zone_tampon equ 1040
taille_tampon equ 100000h


;change la taille de la zt
mov al,8
mov dx,sel_dat1
mov ecx,zone_tampon+taille_tampon
int 61h
cmp eax,0
jne erreur_autres_cmdcop

mov ax,sel_dat1
mov ds,ax
mov es,ax

;recup�re le nom du fichier a copier
mov al,4
mov ah,0
mov cl,0
mov edx,nom_entree
int 61h

;r�cup�re la destination
mov al,4
mov ah,1
mov cl,0
mov edx,nom_sortie
int 61h

xor eax,eax         ;ouvre le fichier source
xor ebx,ebx
mov edx,nom_entree
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov [handle_entree],ebx

mov eax,2         ;cr�e le fichier de destination
xor ebx,ebx
mov edx,nom_sortie
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov [handle_sortie],ebx



;lit la taille du fichier
mov eax,6
mov ah,1
mov ebx,[handle_entree]
mov edx,zone_tampon
int 64h
cmp eax,0
jne erreur_autres_cmdcop
mov ecx,[zone_tampon]
mov [taille_entree],ecx


;r�server un espace pour le nouveau fichier
mov eax,15       
mov ebx,[handle_sortie]
mov ecx,[taille_entree]
int 64h
cmp eax,0
jne erreur_autres_cmdcop

;copie les donn�es dans la destination

boucle_cmd_cop:
cmp dword[taille_entree],taille_tampon
jb suite3_cmdcop 


mov eax,4         ;lit dans le fichier
mov ebx,[handle_entree]
mov ecx,taille_tampon
mov edx,[offset_transfert]
mov edi,zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[handle_sortie]
mov ecx,taille_tampon
mov edx,[offset_transfert]
mov esi,zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop

add dword[offset_transfert],taille_tampon
sub dword[taille_entree],taille_tampon
jmp boucle_cmd_cop

suite3_cmdcop:
cmp dword[taille_entree],0
je ok_cmdcop

mov eax,4         ;lit dans le fichier
mov ebx,[handle_entree]
mov ecx,[taille_entree]
mov edx,[offset_transfert]
mov edi,zone_tampon
int 64h
cmp eax,0
jne erreur_autres_cmdcop

mov eax,5         ;ecrit dans le fichier
mov ebx,[handle_sortie]
mov ecx,[taille_entree]
mov edx,[offset_transfert]
mov esi,zone_tampon 
int 64h
cmp eax,0
jne erreur_autres_cmdcop



ok_cmdcop:
mov al,13
mov ah,0
mov cl,98
mov ch,0
mov edx,zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,nom_entree
int 61h

mov al,13
mov ah,0
mov cl,95
mov ch,0
mov edx,zone_tampon
int 61h
mov al,6
int 61h

mov al,6
mov edx,nom_sortie
int 61h

mov word[zone_tampon],13
mov al,6
mov edx,zone_tampon
int 61h

int 60h



erreur_autres_cmdcop:
push eax

mov al,13
mov ah,0
mov cl,3
mov ch,0
mov edx,zone_tampon
int 61h
mov al,6
int 61h


mov al,3
mov edx,zone_tampon
int 61h
mov al,6
int 61h

mov word[zone_tampon],0D22h  ;" puis CR

pop ecx
mov al,13
mov ah,1
mov ch,0
mov edx,zone_tampon+2
int 61h
mov al,6
mov edx,zone_tampon
int 61h

mov word[zone_tampon],0017h  ;fin de couleur
mov al,6
mov edx,zone_tampon
int 61h

int 60h