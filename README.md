# SeaC
Systeme d'exploitation (operationg system)

organisation du dépot:  
ASM: contient toutes les sources en assembleur  
    ASM/NOYAU noyau  
    ASM/BOOT bootloader  
    ASM/PROG applications  
    ASM/DEF fichier de définitions  
    ASM/compilation.bat scripte batch pour compiler le systeme  
BIN: contient tout les binaires précompilé dont Fasm qui n'est pas sur ce dépot  
    *.fe fichier executable du systeme  
    *.baz code de base du noyau / fichier amorçable réseau  
    *.imb fichier multiboot 1  
    *.img image de disquette  
    *.mbr code pour Master Boot Record  
    *.def fichier de définition (clavier, message, et caractères matriciels)

voir dans le wiki pour plus d'info  

