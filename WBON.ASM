        org 100h
        ; disable cache
        mov     eax, cr0
        or      eax, 40000000h
        mov     cr0, eax
        
        wbinvd

        ; disable LOCK_NW
        mov     al, 0C2h
        out     22h, al
        jmp     short $+2
        in      al, 23h
        and     al, ~04h
        mov     ah, al
        mov     al, 0C2h
        out     22h, al
        mov     al,ah
        out     23h, al
        mov     dl, al

        ; enable NW (not write-through)
        mov     eax, cr0
        or      eax, 20000000h
        mov     cr0, eax

        ; restore LOCK_NW bit
        mov     al, 0C2h
        out     22h, al
        mov     al, dl
        out     23h, al

        ; enable cache
        mov     eax, cr0
        and     eax, ~40000000h
        mov     cr0, eax
        
        ret
