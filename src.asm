; GUI
include win64a.inc  

.code 

; Размер окна
W = 500
H = 500
; Клиентские размеры
_CW = 481
_CH = 441
; Элементы меню
SNAKE_MENU = 30
MENU_RESET = 100

; Структура Змеи
Snake2D struct
	_size dd ?
	points dq ?
	direction db ?
Snake2D ends

; Направление движения

UP      EQU 0
DOWN    EQU 1
LEFT    EQU 2
RIGHT   EQU 3

; Константы змеи
SNAKE_LENGTH = 6 ; Изначальная длина змеи + 1
GRID_SIZE = 20 ; Размер сетки игрового поля
GAME_SPEED = 100


WinMain proc <13>
; Определяем дескриптор окна
local hWnd:HWND
; Определяем структуру MSG для цикла обработки событий
local msg:MSG
; Опеределяем структуру класс окна 
local wnd:WNDCLASSEX

;_______WNDCLASSEX STRUCTURE__________

; Имя класса окна
mov rdi, offset wndName   
mov wnd.lpszClassName, rdi
; Загружаем меню
mov wnd.lpszMenuName, SNAKE_MENU
; Загружаем курсор
invoke LoadCursorA, 0, IDC_ARROW
mov wnd.hCursor, rax
; Загружаем иконку
invoke LoadIconA, 0, IDI_APPLICATION
mov wnd.hIcon, rax
mov wnd.hIconSm, rax

mov wnd.hInstance, 0
; Указатель на функцию-обработчик
mov rax, offset Wndproc
mov wnd.lpfnWndProc, rax

; Размер структуры WNDCLASSEX
mov wnd.cbSize, sizeof WNDCLASSEX

; Цвет фона, смотри на MSDN
mov wnd.hbrBackground, COLOR_WINDOWFRAME
;__________REGISTER WINDOW CLASS__________
invoke RegisterClassExA, &wnd
invoke CreateWindowExA, 0, rdi, rdi, WS_OVERLAPPEDWINDOW or WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, W, H, 0, 0, 0, 0
mov hWnd, rax
; Цикл обработки сообщений
@@: 
       invoke GetMessageA, &msg, hWnd, 0, 0
       invoke DispatchMessageA, &msg
jmp @b
ret
WinMain endp


Wndproc proc <12,8,4,8,8> hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
local hdc:HDC
local hdcMem:HDC
local bmpMem:qword
local ps:PAINTSTRUCT
cmp edx, WM_DESTROY
	je wmDESTROY
cmp edx, WM_CREATE
	je wmCREATE
cmp edx, WM_PAINT
	je wmPAINT
cmp edx, WM_KEYDOWN
	je wmKEYDOWN
cmp edx, WM_TIMER
	je wmTIMER
	invoke DefWindowProcA, hWnd, uMsg, wParam, lParam
	jmp wmBYE
wmDESTROY: 
       invoke ExitProcess, 0
wmCREATE:
		; Инициализируем координаты еды
		invoke time, 0
		invoke srand, rax 
		invoke SpawnFood
		; Инициализируем змею
		mov dword ptr [snake + Snake2D._size], SNAKE_LENGTH
		; Загружаем текстуру сегмента и головы, apple
		invoke LoadImageA, 0, &img_seg, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
		mov hImg_seg, rax
		invoke CreatePatternBrush, rax
		mov segBrush, rax
		invoke DeleteObject, hImg_seg
		
		invoke LoadImageA, 0, &img_head, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
		mov hImg_head, rax
		invoke CreatePatternBrush, rax
		mov headBrush, rax
		invoke DeleteObject, hImg_head
		
		invoke LoadImageA, 0, &img_apple, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
		mov hImg_apple, rax
		invoke CreatePatternBrush, rax
		mov appleBrush, rax
		invoke DeleteObject, hImg_apple
		
		invoke LoadImageA, 0, &img_grid, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
		mov hImg_grid, rax
		invoke CreatePatternBrush, rax
		mov gridBrush, rax
		invoke DeleteObject, hImg_grid
		;mov dword ptr [snake + Snake2D.capacity], SNAKE_LENGTH
		; Выделяем память под сегменты змеи
		; Получаем объект кучи
		invoke GetProcessHeap
		; Выделяем память
		invoke HeapAlloc, rax, HEAP_ZERO_MEMORY, SNAKE_LENGTH * sizeof POINT
		mov qword ptr [snake + Snake2D.points], rax
		; Спавним змею по середине игрового поля
		jmp reset
wmPAINT:
        invoke BeginPaint, hWnd, &ps
		mov hdc, rax
		
		; Создаем совместимый контекст устройства
		invoke CreateCompatibleDC, rax
		mov hdcMem, rax
		invoke CreateCompatibleBitmap, hdc, _CW, _CH
		mov bmpMem, rax
		invoke SelectObject, hdcMem, rax
		
		; Рисуем координатную сетку
		invoke DrawGrid, hWnd, hdcMem
		invoke DrawSnake, hdcMem
		invoke DrawFood, hdcMem
		
		; Копируем на основной контекст 
		invoke BitBlt, hdc, 0, 0, _CW, _CH, hdcMem, 0, 0, SRCCOPY
		
	    invoke EndPaint, hWnd, &ps
		invoke DeleteDC, hdcMem
		invoke DeleteObject, bmpMem
        jmp wmBYE
wmKEYDOWN:
		lea rax, snake
		cmp wParam, VK_LEFT
			je dLEFT
		cmp wParam, VK_RIGHT
			je dRIGHT
		cmp wParam, VK_UP
			je _dUP
		cmp wParam, VK_DOWN
			je dDOWN
		jmp wmBYE
		dLEFT:
			cmp [rax + Snake2D.direction], RIGHT
			je wmBYE
			mov byte ptr [snake + Snake2D.direction], LEFT
			jmp wmBYE
		dRIGHT:
			cmp [rax + Snake2D.direction], LEFT
			je wmBYE
			mov byte ptr [snake + Snake2D.direction], RIGHT
			jmp wmBYE
		_dUP:
			cmp [rax + Snake2D.direction], DOWN
			je wmBYE
			mov byte ptr [snake + Snake2D.direction], UP
			jmp wmBYE
		dDOWN:
			cmp [rax + Snake2D.direction], UP
			je wmBYE
			mov byte ptr [snake + Snake2D.direction], DOWN
		jmp wmBYE
wmTIMER:
	; Адрес массива точек
		mov rbx, qword ptr [snake + Snake2D.points]
		; Размер змеи 
		mov edi, dword ptr [snake + Snake2D._size]
		dec edi ; Голова змеи
		mov ecx, dword ptr [rbx + rdi * Snake2D.points + POINT.x]
		mov edx, dword ptr [rbx + rdi * Snake2D.points + POINT.y]
		lea rax, snake
		cmp [rax + Snake2D.direction], LEFT
			je turnLEFT
		cmp [rax + Snake2D.direction], RIGHT
			je turnRIGHT
		cmp [rax + Snake2D.direction], UP
			je turnUP
		cmp [rax + Snake2D.direction], DOWN
			je turnDOWN
		jmp wmBYE
	turnLEFT:
		dec ecx
		invoke AddSegment, ,
		jmp collision
	turnRIGHT:
		inc ecx
		invoke AddSegment, ,
		jmp collision
	turnDOWN:
		inc edx
		invoke AddSegment, ,
		jmp collision
	turnUP:
		dec edx
		invoke AddSegment, ,
		jmp collision
	collision:
		invoke CheckCollision
		cmp rax, 0
		je _food
		invoke KillTimer, hWnd, 1
		invoke MessageBoxA, 0, "Game over!", "Game over!", MB_OK
		jmp reset
	_food:
		; Яблоко
		lea rdx, food
		mov edi, dword ptr [snake + Snake2D._size]
		dec edi ; Голова змеи
		mov ecx, dword ptr [rbx + rdi * Snake2D.points + POINT.x]
		mov r9d, dword ptr [rbx + rdi * Snake2D.points + POINT.y]
		; Проверка на столкновение с яблоком 
		mov esi, [rdx + POINT.x]
		cmp ecx, esi
		jne @f
		mov r8d, [rdx + POINT.y]
		cmp r9d, r8d
		je true_food
		
	@@:
		invoke RemoveSegment
		invoke InvalidateRect, hWnd, 0, 1
		jmp wmBYE
	true_food:
		invoke SpawnFood
		invoke InvalidateRect, hWnd, 0, 1
		jmp wmBYE
reset:
		; Спавним змею по середине игрового поля
		mov dword ptr [snake + Snake2D._size], SNAKE_LENGTH
		xor rdi, rdi
		@@:
			cmp rdi, SNAKE_LENGTH
			je @f
			; Адрес массива точек
			mov rbx, qword ptr [snake + Snake2D.points]
			; Заполняем точку 
			mov eax, edi
			add eax, 10
			mov dword ptr [rbx + rdi * sizeof POINT + POINT.x],  eax
			mov dword ptr [rbx + rdi * sizeof POINT + POINT.y],  10
			inc rdi
			jmp @b
		@@:
		invoke SpawnFood
		invoke InvalidateRect, hWnd, 0, 1
		; Включаем таймер
		invoke SetTimer, hWnd, 1, GAME_SPEED, 0
	jmp wmBYE
wmBYE:
       ret
ret
Wndproc endp

SpawnFood proc <12> 
	invoke rand
	mov ebx, _CW / GRID_SIZE
	div ebx
	mov dword ptr [food + POINT.x], edx
	invoke rand
	mov ebx, _CH / GRID_SIZE
	div ebx
	mov dword ptr [food + POINT.y], edx
ret
SpawnFood endp

DrawSnake proc <12, 8> hdc:HDC
	local oldPen:qword
	local oldBrush:qword
	local pt:POINT ; Текущие координаты
	mov rbx, qword ptr [snake + Snake2D.points]
	imul edx, dword ptr [rbx + POINT.x], GRID_SIZE
	imul r8d, dword ptr [rbx + POINT.y], GRID_SIZE
	; Ставим кисть на tail змеи
	invoke MoveToEx, hdc, , , 0
	
	; Создаем кисть из текстуры для сегментов
	invoke SelectObject, hdc, segBrush
	mov oldBrush, rax
	; Создаем перо прозрачного цвета
	invoke DeleteObject, oldPen
	invoke CreatePen, PS_SOLID , 0, 0080a080h
	invoke SelectObject, hdc, rax
	mov oldPen, rax
	; Рисуем сегменты змеи
	mov rdi, 1
	mov esi, dword ptr [snake + Snake2D._size]
	dec esi
	@@:
		cmp edi, esi
		je @f
		mov rbx, qword ptr [snake + Snake2D.points]
		imul edx, dword ptr [rbx + rdi * sizeof POINT + POINT.x], GRID_SIZE
		imul r8d, dword ptr [rbx + rdi * sizeof POINT + POINT.y], GRID_SIZE
		mov eax, edx
		add eax, GRID_SIZE
		mov r9d, eax
		mov eax, r8d
		add eax, GRID_SIZE
		invoke Rectangle, hdc, , , , eax
		inc rdi
		jmp @b
	@@:
	; Чистим ресурсы
	invoke DeleteObject, oldPen
	invoke SelectObject, hdc, oldBrush
	
	; Отдельно раскрашиваем голову в другую текстуру
	invoke SelectObject, hdc, headBrush
	mov oldBrush, rax
	imul edx, dword ptr [rbx + rdi * sizeof POINT + POINT.x], GRID_SIZE
	imul r8d, dword ptr [rbx + rdi * sizeof POINT + POINT.y], GRID_SIZE
	mov eax, edx
	add eax, GRID_SIZE
	mov r9d, eax
	mov eax, r8d
	add eax, GRID_SIZE
	invoke Rectangle, hdc, , , , eax
	; Чистим ресурсы
	invoke DeleteObject, oldPen
	invoke SelectObject, hdc, oldBrush
	ret
DrawSnake endp

DrawGrid proc <12, 8, 8> hWnd:HWND, hdc:HDC
local oldPen:qword
local oldBrush:qword

	invoke CreatePen, PS_SOLID, 1, 00675797h
	invoke SelectObject, hdc, rax
	mov oldPen, rax
	invoke CreateSolidBrush, 00555174h
	invoke SelectObject, hdc, rax
	mov oldBrush, rax
    ; Рисуем прямоугольники
    xor rdi, rdi ; Y координата
DrawGrid_Y:
    cmp rdi, _CH
    jg DrawGrid_End

    xor rsi, rsi ; X координата
DrawGrid_X:
    cmp rsi, _CW
    jg DrawGrid_NextRow

    ; рисуем прямоугольник
    mov rax, rsi 
    add rax, GRID_SIZE
    mov rbx, rdi
    add rbx, GRID_SIZE
    invoke Rectangle, hdc, rsi, rdi, rax, rbx

    add rsi, GRID_SIZE
    jmp DrawGrid_X
DrawGrid_NextRow:
    add rdi, GRID_SIZE
    jmp DrawGrid_Y
DrawGrid_End:
	; Чистим ресурсы
	invoke DeleteObject, oldPen
	invoke SelectObject, hdc, oldBrush
ret
DrawGrid endp



DrawFood proc <12, 8> hdc:HDC
local oldBrush:qword
local oldPen:qword
	invoke CreatePen, PS_NULL , 0, 0
	invoke SelectObject, hdc, rax
	mov oldPen, rax
	invoke SelectObject, hdc, appleBrush
	mov oldBrush, rax
	imul edx, dword ptr [food + POINT.x], GRID_SIZE
	imul r8d, dword ptr [food + POINT.y], GRID_SIZE
	mov eax, edx
	add eax, GRID_SIZE
	mov r9d, eax
	mov eax, r8d
	add eax, GRID_SIZE
	invoke Rectangle, hdc, , , , eax
	
	invoke SelectObject, hdc, oldBrush
	invoke SelectObject, hdc, oldPen
	invoke DeleteObject, rax
ret
DrawFood endp

AddSegment proc <12, 4, 4> x:dword, y:dword
	local hHeap:qword
	
	; Выделяем памяти на 1 сегмент больше
	add dword ptr [snake + Snake2D._size], 1
	invoke GetProcessHeap
	mov hHeap, rax
	mov rbx, qword ptr [snake + Snake2D.points]
	imul r9d, dword ptr [snake + Snake2D._size], sizeof POINT
	invoke HeapReAlloc, rax, HEAP_ZERO_MEMORY, rbx, 
	mov qword ptr [snake + Snake2D.points], rax
	mov rbx, qword ptr [snake + Snake2D.points]
	mov eax, x
	mov edi, dword ptr [snake + Snake2D._size]
	dec rdi
	mov dword ptr [rbx + rdi * sizeof POINT + POINT.x], eax
	mov eax, y
	mov dword ptr [rbx + rdi * sizeof POINT + POINT.y], eax
	ret
AddSegment endp


RemoveSegment proc <12>
	mov rbx, qword ptr [snake + Snake2D.points]
	mov edi, dword ptr [snake + Snake2D._size]
	dec edi
	xor rsi, rsi
	@@:
		cmp esi, edi
		jnl @f
		mov rax, qword ptr [rbx + rsi * sizeof POINT]
		mov r10, rsi
		inc r10
		mov rdx, qword ptr [rbx +  r10 * sizeof POINT]
		xchg rax, rdx
		mov qword ptr [rbx + rsi * sizeof POINT], rax
		mov qword ptr [rbx +  r10 * sizeof POINT], rdx
		inc esi
		jmp @b
	@@:
		mov dword ptr [snake + Snake2D._size], edi
	ret
RemoveSegment endp

; Проверяем на столкновение змеи с собой или с игровым полем
CheckCollision proc <12>
	; точки 
	mov rbx, qword ptr [snake + Snake2D.points]
	; размер 
	mov eax, dword ptr [snake + Snake2D._size]
	dec rax
	; Голова змеи
	lea rax, [rbx + rax * sizeof POINT]
	; Проверка на столкновение с игровым полем
	cmp [rax + POINT.x], 0
	jl true
	cmp [rax + POINT.y], 0
	jl true
	cmp [rax + POINT.x], _CW / GRID_SIZE
	jg true
	cmp [rax + POINT.y], _CH / GRID_SIZE
	jg true
	
	; Проверка на столкновение сама с собой
	xor rsi, rsi
	inc rsi
	mov edi, dword ptr [snake + Snake2D._size]
	dec rdi
	_loop:
		cmp rsi, rdi
		je false
		mov ecx, dword ptr [rbx + rsi * sizeof POINT + POINT.x]
		mov edx, dword ptr [rbx + rsi * sizeof POINT + POINT.y]
		cmp ecx, [rax + POINT.x]
		jne @f
		cmp edx, [rax + POINT.y]
		je true
	@@:
		inc rsi
		jmp _loop
	jmp false
	true:
		mov rax, 1
		ret
	false:
		xor rax, rax
ret
CheckCollision endp

.data
wndName db "Snake 2D", 0 ; Window Name
img_head db "head.bmp", 0
img_seg db "seg.bmp", 0
img_apple db "apple.bmp", 0
img_grid db "grid.bmp", 0
hImg_grid dq ?
hImg_head dq ?
hImg_seg dq ?
hImg_apple dq ?
appleBrush dq ?
gridBrush dq ?
headBrush dq ?
segBrush dq ?
snake Snake2D <?>
food POINT <?>
end