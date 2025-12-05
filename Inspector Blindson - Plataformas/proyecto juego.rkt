#lang racket
; Usamos 2htdp/image para dibujar y 2htdp/universe para el motor de juego.
(require 2htdp/image)
(require 2htdp/universe)

; ====================================================
; 1. CONFIGURACIÓN Y CONSTANTES
; ====================================================

; Parámetros de la Ventana
(define BIG-BANG-WIDTH 950)
(define BIG-BANG-HEIGHT 650)

; Parámetros de FÍSICA y JUEGO
(define JUGADOR-VELOCIDAD 15)
(define JUMP-STRENGTH -18)        ; Fuerza inicial del salto (Negativo para ir hacia arriba)
(define GRAVITY 1.5)              ; Aceleración de la gravedad (caída)
(define TICK-RATE 1/30)           ; Tasa de actualización: 30 veces por segundo
(define FALL-MARGIN 10)           ; Margen extra (en píxeles) para no caerse del borde.

; Parámetros del Cuadro Móvil 1 (Plataforma Morada - PELIGRO)
(define CUADRO-1-SPEED 2)
(define CUADRO-1-WIDTH 180)       ; Ancho de la plataforma C1
(define CUADRO-1-HEIGHT 200)      ; Alto de la plataforma C1
(define CUADRO-1-Y-MIN 150)       ; El punto Y (TOP) más alto de C1
(define CUADRO-1-Y-MAX 310)       ; El punto Y (TOP) más bajo de C1

; Parámetros del Cuadro Móvil 2 (Plataforma Negra - MORTAL)
(define CUADRO-2-SPEED 2.8)
(define CUADRO-2-WIDTH 100)       ; Ancho de la plataforma C2
(define CUADRO-2-HEIGHT 200)      ; Alto de la plataforma C2
(define CUADRO-2-Y-MIN 130)       ; El punto Y (TOP) más alto de C2
(define CUADRO-2-Y-MAX 310)       ; El punto Y (TOP) más bajo de C2
(define CUADRO-2-X-CENTER 460)    ; Centro X del Cuadro 2
(define CUADRO-2-X-START (- CUADRO-2-X-CENTER (/ CUADRO-2-WIDTH 2))) ; 410
(define CUADRO-2-X-END (+ CUADRO-2-X-CENTER (/ CUADRO-2-WIDTH 2)))   ; 510

; Parámetros del Cuadro Móvil 3 (Plataforma Roja - MORTAL)
(define CUADRO-3-SPEED 2.8)
(define CUADRO-3-WIDTH 200)       ; Ancho de la plataforma C3
(define CUADRO-3-HEIGHT 220)      ; Alto de la plataforma C3
(define CUADRO-3-Y-MIN 120)       ; El punto Y (TOP) más alto de C3
(define CUADRO-3-Y-MAX 310)       ; El punto Y (TOP) más bajo de C3
(define CUADRO-3-X-CENTER 675)    ; Centro X del Cuadro 3
(define CUADRO-3-X-START (- CUADRO-3-X-CENTER (/ CUADRO-3-WIDTH 2))) ; 575
(define CUADRO-3-X-END (+ CUADRO-3-X-CENTER (/ CUADRO-3-WIDTH 2)))   ; 775

; Parámetros de la PUERTA (META) - NIVEL 1
(define PUERTA-WIDTH 60)
(define PUERTA-HEIGHT 60)
(define PUERTA-X 820)
(define PUERTA-Y 515)

; RUTA del Fondo (Usando un color de fondo ya que la imagen no está disponible)
; Si tienes la imagen, cambia esto por (bitmap/file "tu-imagen.jpeg")
(define IMAGEN-FONDO-PATH "menu-convertido-a-950x650.jpeg")

; --- Botones de Menú Principal ---
(define BUTTON-WIDTH 200)
(define BUTTON-HEIGHT 60)
(define PLAY-BUTTON-X 475)
(define PLAY-BUTTON-Y 550)
(define RETURN-BUTTON-W 100)
(define RETURN-BUTTON-H 40)
(define RETURN-BUTTON-X 890)
(define RETURN-BUTTON-Y 30)
(define NIVEL-BUTTON-W 180)
(define NIVEL-BUTTON-H 120)
(define NIVEL-Y 325)
(define NIVEL-1-X 237)
(define NIVEL-2-X 475)
(define NIVEL-3-X 712)

; =========================================================================
; *** PARÁMETROS DEL JUGADOR ***
; =========================================================================
(define JUGADOR-WIDTH 30)
(define JUGADOR-HEIGHT 50)
; =========================================================================

; --- CONSTANTES DERIVADAS ---
(define JUGADOR-HALF-WIDTH (/ JUGADOR-WIDTH 2))
(define JUGADOR-HALF-HEIGHT (/ JUGADOR-HEIGHT 2))

; --- CONSTANTES DE LÍMITES Y SUELOS ---
(define JUGADOR-Y-SUELO 545) ; Suelo inferior de la ventana

; Límites de Paredes Exteriores
(define PARED-IZQ-X 50)
(define PARED-DER-X 900)
(define LIMITE-IZQ-CENTRO (+ PARED-IZQ-X JUGADOR-HALF-WIDTH))
(define LIMITE-DER-CENTRO (- PARED-DER-X JUGADOR-HALF-WIDTH))

; ====================================================
; PARÁMETROS DEL NIVEL 2
; ====================================================

; Plataforma Inicial del Jugador (Izquierda) - NIVEL 2
(define N2-PLATAFORMA-INICIAL-X-START 50)
(define N2-PLATAFORMA-INICIAL-X-END 200)
(define N2-PLATAFORMA-INICIAL-WIDTH (- N2-PLATAFORMA-INICIAL-X-END N2-PLATAFORMA-INICIAL-X-START)) ; 150
(define N2-PLATAFORMA-INICIAL-Y-TOP 300)
(define N2-PLATAFORMA-INICIAL-Y-BOTTOM 545)
(define N2-PLATAFORMA-INICIAL-HEIGHT (- N2-PLATAFORMA-INICIAL-Y-BOTTOM N2-PLATAFORMA-INICIAL-Y-TOP)) ; 245
(define N2-PLATAFORMA-INICIAL-X-CENTER (/ (+ N2-PLATAFORMA-INICIAL-X-START N2-PLATAFORMA-INICIAL-X-END) 2)) ; 125
(define N2-PLATAFORMA-INICIAL-Y-CENTER (/ (+ N2-PLATAFORMA-INICIAL-Y-TOP N2-PLATAFORMA-INICIAL-Y-BOTTOM) 2)) ; 422.5

; Posición inicial del jugador en Nivel 2 (50 píxeles ARRIBA de la plataforma)
(define N2-JUGADOR-START-X 125)
(define N2-JUGADOR-START-Y (- N2-PLATAFORMA-INICIAL-Y-TOP JUGADOR-HALF-HEIGHT 50)) ; 225 (50 píxeles más arriba)

; Y donde el jugador aterriza sobre la plataforma café
(define N2-PLATAFORMA-LANDING-Y (- N2-PLATAFORMA-INICIAL-Y-TOP JUGADOR-HALF-HEIGHT)) ; 275

; Límites de colisión de la plataforma café IZQUIERDA para el jugador
(define N2-PLATAFORMA-X-MIN-CENTER (+ N2-PLATAFORMA-INICIAL-X-START JUGADOR-HALF-WIDTH)) ; 65
(define N2-PLATAFORMA-X-MAX-CENTER (- N2-PLATAFORMA-INICIAL-X-END JUGADOR-HALF-WIDTH)) ; 185

; ====================================================
; PLATAFORMA CAFÉ DERECHA - NIVEL 2
; ====================================================
(define N2-PLATAFORMA-DERECHA-X-END 850)
(define N2-PLATAFORMA-DERECHA-X-START (- N2-PLATAFORMA-DERECHA-X-END N2-PLATAFORMA-INICIAL-WIDTH)) ; 700
(define N2-PLATAFORMA-DERECHA-WIDTH N2-PLATAFORMA-INICIAL-WIDTH) ; 150
(define N2-PLATAFORMA-DERECHA-Y-TOP N2-PLATAFORMA-INICIAL-Y-TOP) ; 300
(define N2-PLATAFORMA-DERECHA-Y-BOTTOM N2-PLATAFORMA-INICIAL-Y-BOTTOM) ; 545
(define N2-PLATAFORMA-DERECHA-HEIGHT N2-PLATAFORMA-INICIAL-HEIGHT) ; 245
(define N2-PLATAFORMA-DERECHA-X-CENTER (/ (+ N2-PLATAFORMA-DERECHA-X-START N2-PLATAFORMA-DERECHA-X-END) 2)) ; 775
(define N2-PLATAFORMA-DERECHA-Y-CENTER N2-PLATAFORMA-INICIAL-Y-CENTER) ; 422.5

; Límites de colisión de la plataforma café DERECHA para el jugador
(define N2-PLATAFORMA-DERECHA-X-MIN-CENTER (+ N2-PLATAFORMA-DERECHA-X-START JUGADOR-HALF-WIDTH)) ; 715
(define N2-PLATAFORMA-DERECHA-X-MAX-CENTER (- N2-PLATAFORMA-DERECHA-X-END JUGADOR-HALF-WIDTH)) ; 835

; Piso principal del Nivel 2
(define N2-PISO-Y 545)

; Límites del Nivel 2 (usan las mismas paredes)
(define N2-LIMITE-IZQ-CENTRO LIMITE-IZQ-CENTRO)
(define N2-LIMITE-DER-CENTRO LIMITE-DER-CENTRO)

; ====================================================
; ESCALERA - NIVEL 2
; ====================================================
(define N2-ESCALERA-X-START 650)
(define N2-ESCALERA-X-END 690)
(define N2-ESCALERA-Y-TOP 250)
(define N2-ESCALERA-Y-BOTTOM 545)
(define N2-ESCALERA-WIDTH (- N2-ESCALERA-X-END N2-ESCALERA-X-START)) ; 40
(define N2-ESCALERA-HEIGHT (- N2-ESCALERA-Y-BOTTOM N2-ESCALERA-Y-TOP)) ; 245
(define N2-ESCALERA-X-CENTER (/ (+ N2-ESCALERA-X-START N2-ESCALERA-X-END) 2)) ; 670
(define N2-ESCALERA-Y-CENTER (/ (+ N2-ESCALERA-Y-TOP N2-ESCALERA-Y-BOTTOM) 2)) ; 422.5

; Velocidad de subida en la escalera
(define N2-ESCALERA-CLIMB-SPEED -8) ; Negativo para subir

; Función: ¿Está el jugador tocando la escalera horizontalmente?
(define (esta-en-escalera-x? jugador-x)
  (and (>= jugador-x (- N2-ESCALERA-X-START JUGADOR-HALF-WIDTH))
       (<= jugador-x (+ N2-ESCALERA-X-END JUGADOR-HALF-WIDTH))))

; Función: ¿Está el jugador tocando la escalera verticalmente?
(define (esta-en-escalera-y? jugador-y)
  (and (>= jugador-y N2-ESCALERA-Y-TOP)
       (<= jugador-y N2-ESCALERA-Y-BOTTOM)))

; Función: ¿Está el jugador en la escalera?
(define (esta-en-escalera? jugador-x jugador-y)
  (and (esta-en-escalera-x? jugador-x)
       (esta-en-escalera-y? jugador-y)))

; ====================================================
; PUERTA META - NIVEL 2
; ====================================================
(define N2-PUERTA-WIDTH 60)
(define N2-PUERTA-HEIGHT 60)
(define N2-PUERTA-X 790) ; Centro entre 745 y 835
(define N2-PUERTA-Y 270) ; Centro entre 240 y 300

; --- CONSTANTES DE LA PLATAFORMA 2 (PISO GRANDE - Fijo) ---
(define PLATAFORMA-2-TOP 510) ; Borde superior de P2
(define PLATAFORMA-2-HEIGHT 155)
(define PLATAFORMA-BOTTOM (+ PLATAFORMA-2-TOP PLATAFORMA-2-HEIGHT)) ; Borde inferior de P2
(define PISO-2-Y (- PLATAFORMA-2-TOP JUGADOR-HALF-HEIGHT)) ; Y central del jugador cuando está en P2
(define PISO-2-WIDTH 590)
(define PISO-2-X-CENTER 475)
(define PISO-2-X-START (- PISO-2-X-CENTER (/ PISO-2-WIDTH 2)))
(define PISO-2-X-END (+ PISO-2-X-CENTER (/ PISO-2-WIDTH 2)))
(define PISO-2-VISUAL-Y (+ PLATAFORMA-2-TOP (/ PLATAFORMA-2-HEIGHT 2)))
(define PISO-2-X-MIN-CENTER (+ PISO-2-X-START JUGADOR-HALF-WIDTH))
(define PISO-2-X-MAX-CENTER (- PISO-2-X-END JUGADOR-HALF-WIDTH))

; --- CONSTANTES DEL CUADRO MÓVIL 1 (Plataforma Morada - PELIGRO) ---
(define CUADRO-1-X-CENTER 275)
(define CUADRO-1-X-START (- CUADRO-1-X-CENTER (/ CUADRO-1-WIDTH 2))) ; 200
(define CUADRO-1-X-END (+ CUADRO-1-X-CENTER (/ CUADRO-1-WIDTH 2)))    ; 350
(define CUADRO-1-X-MIN-CENTER (+ CUADRO-1-X-START JUGADOR-HALF-WIDTH)) ; 215
(define CUADRO-1-X-MAX-CENTER (- CUADRO-1-X-END JUGADOR-HALF-WIDTH))   ; 335

; Rango horizontal seguro (sin caerse) para CUADRO 1 (con margen)
(define CUADRO-1-SAFE-X-MIN (- CUADRO-1-X-MIN-CENTER FALL-MARGIN))
(define CUADRO-1-SAFE-X-MAX (+ CUADRO-1-X-MAX-CENTER FALL-MARGIN))

; Función: ¿Está el jugador horizontalmente sobre C1 (rango SÓLIDO)?
(define (esta-en-cuadro-1-rango? jugador-x)
  (and (>= jugador-x CUADRO-1-X-MIN-CENTER)
       (<= jugador-x CUADRO-1-X-MAX-CENTER)))

; Función: ¿Está el jugador horizontalmente sobre C1 (rango con MARGEN para no caerse)?
(define (esta-en-cuadro-1-rango-con-margen? jugador-x)
  (and (>= jugador-x CUADRO-1-SAFE-X-MIN)
       (<= jugador-x CUADRO-1-SAFE-X-MAX)))

; --- CONSTANTES DE LAS PAREDES DE BLOQUEO PERMANENTES (Paredes 1 y 2 - Fijas) ---
(define PARED-BLOQUEO-WIDTH 10)
(define PARED-BLOQUEO-HALF-WIDTH (/ PARED-BLOQUEO-WIDTH 2))
(define PARED-BLOQUEO-HEIGHT JUGADOR-HEIGHT)
(define PARED-BLOQUEO-Y-CENTER JUGADOR-Y-SUELO) ; Se dibujan sobre el suelo principal
(define PARED-BLOQUEO-1-X 200)
(define PARED-BLOQUEO-2-X 750)
; Rangos de X para colisionar con Pared 1 y 2
(define PARED-1-BLOQUEO-MIN-X (- PARED-BLOQUEO-1-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-1-BLOQUEO-MAX-X (+ PARED-BLOQUEO-1-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-2-BLOQUEO-MIN-X (- PARED-BLOQUEO-2-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-2-BLOQUEO-MAX-X (+ PARED-BLOQUEO-2-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
; Rango de Y donde las Paredes 1 y 2 bloquean al jugador
(define PARED-BLOQUEO-Y-TOP (- PARED-BLOQUEO-Y-CENTER JUGADOR-HALF-HEIGHT))
(define PARED-BLOQUEO-Y-BOTTOM (+ PARED-BLOQUEO-Y-CENTER JUGADOR-HALF-HEIGHT))

; Comprueba si el jugador está en el rango vertical de las Paredes 1 y 2 (FIJAS)
(define (is-in-block-wall-y-range? current-y)
  (and (>= current-y PARED-BLOQUEO-Y-TOP)
       (<= current-y PARED-BLOQUEO-Y-BOTTOM)))

; --- PAREDES LATERALES DE CUADRO 1 (Paredes 3 y 4 - MÓVILES) ---
(define C1-BLOQUEO-HEIGHT CUADRO-1-HEIGHT) ; 200 de alto

; Coordenadas X de los centros de las nuevas paredes (coinciden con los bordes de C1):
(define PARED-BLOQUEO-3-X CUADRO-1-X-START) ; 200 (Borde izquierdo de C1)
(define PARED-BLOQUEO-4-X CUADRO-1-X-END)    ; 350 (Borde derecho de C1)

; Rangos de X para colisionar con Pared 3 y 4
(define PARED-3-BLOQUEO-MIN-X (- PARED-BLOQUEO-3-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-3-BLOQUEO-MAX-X (+ PARED-BLOQUEO-3-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-4-BLOQUEO-MIN-X (- PARED-BLOQUEO-4-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))
(define PARED-4-BLOQUEO-MAX-X (+ PARED-BLOQUEO-4-X PARED-BLOQUEO-HALF-WIDTH JUGADOR-HALF-WIDTH))

; Función: Colisión vertical DINÁMICA para las Paredes 3 y 4 (se mueven con C1)
(define (is-in-c1-block-wall-y-range? current-y cuadro-1-y)
  ; cuadro-1-y es el Y TOP del bloque morado
  (define MIN-Y-CENTER (+ cuadro-1-y JUGADOR-HALF-HEIGHT)) ; Y central del jugador si su pie toca el borde inferior de la pared
  (define MAX-Y-CENTER (- (+ cuadro-1-y CUADRO-1-HEIGHT) JUGADOR-HALF-HEIGHT)) ; Y central del jugador si su cabeza toca el borde superior de la pared

  (and (>= current-y MIN-Y-CENTER)
       (<= current-y MAX-Y-CENTER)))

; ====================================================
; 2. DEFINICIÓN DEL MUNDO
; ====================================================

; world: almacena el estado completo del juego.
; Agregamos 'nivel-actual' para saber en qué nivel estamos
(define-struct world (scene nivel-actual jugador-x jugador-y jugador-vy cuadro-1-y cuadro-1-dy cuadro-2-y cuadro-2-dy cuadro-3-y cuadro-3-dy))

; ====================================================
; 3. CREACIÓN DE GRÁFICOS
; ====================================================

; A. Cargar el Fondo (Ajustado para usar un color de fondo si no encuentra la imagen)
(define FONDO-MENU
  (if (file-exists? IMAGEN-FONDO-PATH)
      (bitmap/file IMAGEN-FONDO-PATH)
      (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "darkslategray"))) ; Fondo de respaldo si la imagen no está

; B. El Fondo de la Zona de Juego (Placeholder)
(define FONDO-JUEGO
  (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "darkgreen"))

; C. El Fondo de la SELECCIÓN DE NIVEL
(define FONDO-SELECCION-NIVEL
    (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "darkblue"))

; D. El Jugador (Rectángulo amarillo, el personaje)
(define JUGADOR-IMAGEN
  (rectangle JUGADOR-WIDTH JUGADOR-HEIGHT "solid" "yellow"))

; E. Imagen de la Plataforma 2 (Piso Grande - Gris)
(define PLATAFORMA-2-IMAGEN
  (rectangle PISO-2-WIDTH PLATAFORMA-2-HEIGHT "solid" "gray"))

; F. Imagen del Cuadro Móvil 1 (Plataforma Morada - PELIGRO)
(define PLATAFORMA-1-IMAGEN
  (rectangle CUADRO-1-WIDTH CUADRO-1-HEIGHT "solid" "purple"))

; F2. Imagen del Cuadro Móvil 2 (Plataforma Negra - MORTAL)
(define PLATAFORMA-CUADRO-2-IMAGEN
  (rectangle CUADRO-2-WIDTH CUADRO-2-HEIGHT "solid" "black"))

; F3. Imagen del Cuadro Móvil 3 (Plataforma Roja - MORTAL)
(define PLATAFORMA-CUADRO-3-IMAGEN
  (rectangle CUADRO-3-WIDTH CUADRO-3-HEIGHT "solid" "red"))

; G. Imagen de la Pared de Bloqueo (Vertical - Roja)
(define PARED-BLOQUEO-IMAGEN
  (rectangle PARED-BLOQUEO-WIDTH PARED-BLOQUEO-HEIGHT "solid" "red"))

; H. Imagen de las Paredes laterales de C1 (Móviles - Naranja)
(define C1-PARED-LATERAL-IMAGEN
  (rectangle PARED-BLOQUEO-WIDTH C1-BLOQUEO-HEIGHT "solid" "orange"))

; I. Botones del Menú
(define PLAY-TEXT (text "JUGAR" 30 "white"))
(define PLAY-BACKGROUND (rectangle BUTTON-WIDTH BUTTON-HEIGHT "solid" "blue"))
(define PLAY-BUTTON (overlay PLAY-TEXT PLAY-BACKGROUND))

(define RETURN-TEXT (text "MENÚ" 20 "white"))
(define RETURN-BACKGROUND (rectangle RETURN-BUTTON-W RETURN-BUTTON-H "solid" "maroon"))
(define RETURN-BUTTON (overlay RETURN-TEXT RETURN-BACKGROUND))

; J. Botones de Nivel (Función Auxiliar)
(define (crear-boton-nivel numero color)
    (overlay (text (string-append "NIVEL " (number->string numero)) 30 "black")
             (rectangle NIVEL-BUTTON-W NIVEL-BUTTON-H "solid" color)))

(define NIVEL-1-BUTTON (crear-boton-nivel 1 "lightgreen"))
(define NIVEL-2-BUTTON (crear-boton-nivel 2 "yellow"))
(define NIVEL-3-BUTTON (crear-boton-nivel 3 "orange"))

; K. Imagen de la Puerta (Meta del nivel)
(define PUERTA-IMAGEN
  (overlay (text "META" 16 "white")
           (rectangle PUERTA-WIDTH PUERTA-HEIGHT "solid" "green")))

; L. Imágenes del NIVEL 2
; Plataforma inicial izquierda (donde empieza el jugador)
(define N2-PLATAFORMA-INICIAL-IMAGEN
  (rectangle N2-PLATAFORMA-INICIAL-WIDTH N2-PLATAFORMA-INICIAL-HEIGHT "solid" "brown"))

; Plataforma derecha (idéntica a la izquierda)
(define N2-PLATAFORMA-DERECHA-IMAGEN
  (rectangle N2-PLATAFORMA-DERECHA-WIDTH N2-PLATAFORMA-DERECHA-HEIGHT "solid" "brown"))

; Escalera
(define N2-ESCALERA-IMAGEN
  (rectangle N2-ESCALERA-WIDTH N2-ESCALERA-HEIGHT "solid" "gray"))

; Piso principal Nivel 2
(define N2-PISO-IMAGEN
  (rectangle (- BIG-BANG-WIDTH 100) 10 "solid" "darkgray"))

; Puerta Meta Nivel 2
(define N2-PUERTA-IMAGEN
  (overlay (text "META" 16 "white")
           (rectangle N2-PUERTA-WIDTH N2-PUERTA-HEIGHT "solid" "green")))

; ====================================================
; 4. FUNCIONES PRINCIPALES Y LÓGICA
; ====================================================

; Auxiliar: Estado de inicio limpio para el Nivel 1 (usado para REINICIAR)
(define (nivel-1-start-world)
  (make-world 'jugando 1 100 JUGADOR-Y-SUELO 0 CUADRO-1-Y-MIN CUADRO-1-SPEED CUADRO-2-Y-MIN CUADRO-2-SPEED CUADRO-3-Y-MIN CUADRO-3-SPEED))

; Auxiliar: Estado de inicio limpio para el Nivel 2
(define (nivel-2-start-world)
  (make-world 'jugando 2 N2-JUGADOR-START-X N2-JUGADOR-START-Y 0 0 0 0 0 0 0))

; Función: ¿El jugador alcanzó la puerta? (NIVEL 1)
(define (jugador-en-puerta? jugador-x jugador-y)
  (let* ([puerta-left (- PUERTA-X (/ PUERTA-WIDTH 2))]
         [puerta-right (+ PUERTA-X (/ PUERTA-WIDTH 2))]
         [puerta-top (- PUERTA-Y (/ PUERTA-HEIGHT 2))]
         [puerta-bottom (+ PUERTA-Y (/ PUERTA-HEIGHT 2))]
         [p-left (- jugador-x JUGADOR-HALF-WIDTH)]
         [p-right (+ jugador-x JUGADOR-HALF-WIDTH)]
         [p-top (- jugador-y JUGADOR-HALF-HEIGHT)]
         [p-bottom (+ jugador-y JUGADOR-HALF-HEIGHT)])
    (and (< p-left puerta-right)
         (> p-right puerta-left)
         (< p-top puerta-bottom)
         (> p-bottom puerta-top))))

; Función: ¿El jugador alcanzó la puerta del NIVEL 2?
(define (jugador-en-puerta-n2? jugador-x jugador-y)
  (let* ([puerta-left (- N2-PUERTA-X (/ N2-PUERTA-WIDTH 2))]
         [puerta-right (+ N2-PUERTA-X (/ N2-PUERTA-WIDTH 2))]
         [puerta-top (- N2-PUERTA-Y (/ N2-PUERTA-HEIGHT 2))]
         [puerta-bottom (+ N2-PUERTA-Y (/ N2-PUERTA-HEIGHT 2))]
         [p-left (- jugador-x JUGADOR-HALF-WIDTH)]
         [p-right (+ jugador-x JUGADOR-HALF-WIDTH)]
         [p-top (- jugador-y JUGADOR-HALF-HEIGHT)]
         [p-bottom (+ jugador-y JUGADOR-HALF-HEIGHT)])
    (and (< p-left puerta-right)
         (> p-right puerta-left)
         (< p-top puerta-bottom)
         (> p-bottom puerta-top))))

; Función: ¿Hay colisión mortal (Jugador dentro del Cuadro 1, 2 O 3)?
(define (is-deadly-collision? jugador-x jugador-y cuadro-1-y cuadro-2-y cuadro-3-y)
  (let* (
        ; --- CUADRO 1 (Morado) ---
        (c1-left CUADRO-1-X-START)
        (c1-right CUADRO-1-X-END)
        (c1-top cuadro-1-y)
        (c1-bottom (+ cuadro-1-y CUADRO-1-HEIGHT))

        ; --- CUADRO 2 (Negro) ---
        (c2-left CUADRO-2-X-START)
        (c2-right CUADRO-2-X-END)
        (c2-top cuadro-2-y)
        (c2-bottom (+ cuadro-2-y CUADRO-2-HEIGHT))

        ; --- CUADRO 3 (Rojo) ---
        (c3-left CUADRO-3-X-START)
        (c3-right CUADRO-3-X-END)
        (c3-top cuadro-3-y)
        (c3-bottom (+ cuadro-3-y CUADRO-3-HEIGHT))

        ; --- JUGADOR ---
        (p-left (- jugador-x JUGADOR-HALF-WIDTH))
        (p-right (+ jugador-x JUGADOR-HALF-WIDTH))
        (p-top (- jugador-y JUGADOR-HALF-HEIGHT))
        (p-bottom (+ jugador-y JUGADOR-HALF-HEIGHT))
        )
    (or
      ; Colisión con Cuadro 1
      (and (< p-left c1-right)
           (> p-right c1-left)
           (< p-top c1-bottom)
           (> p-bottom c1-top))
      
      ; Colisión con Cuadro 2
      (and (< p-left c2-right)
           (> p-right c2-left)
           (< p-top c2-bottom)
           (> p-bottom c2-top))

      ; Colisión con Cuadro 3
      (and (< p-left c3-right)
           (> p-right c3-left)
           (< p-top c3-bottom)
           (> p-bottom c3-top)))))


; Función auxiliar: Detecta si las coordenadas caen en el botón
(define (es-click-en-boton? click-x click-y boton-x boton-y boton-w boton-h)
  (and (<= (- boton-x (/ boton-w 2)) click-x (+ boton-x (/ boton-w 2))) ; Verifica X
       (<= (- boton-y (/ boton-h 2)) click-y (+ boton-y (/ boton-h 2))))) ; Verifica Y

; Función: Chequeo de rango horizontal CON MARGEN (Usado para aterrizaje y caída de P2)
(define (esta-en-rango-con-margen? jugador-x)
  (let ([LEFT-SAFE-X (- PISO-2-X-MIN-CENTER FALL-MARGIN)]
        [RIGHT-SAFE-X (+ PISO-2-X-MAX-CENTER FALL-MARGIN)])
    (and (>= jugador-x LEFT-SAFE-X)
         (<= jugador-x RIGHT-SAFE-X))))

; Función: Comprueba si el movimiento horizontal choca con alguna pared de bloqueo
(define (check-block-wall-collision? next-x current-y current-c1-y)
  (or
    ; Colisión con Pared 1 y 2 (Fijas, sobre suelo principal)
    (if (is-in-block-wall-y-range? current-y)
        (or (and (>= next-x PARED-1-BLOQUEO-MIN-X)
                  (<= next-x PARED-1-BLOQUEO-MAX-X))
            (and (>= next-x PARED-2-BLOQUEO-MIN-X)
                  (<= next-x PARED-2-BLOQUEO-MAX-X)))
        #false)

    ; Colisión con Pared 3 (Izquierda de C1 - MÓVIL)
    (if (is-in-c1-block-wall-y-range? current-y current-c1-y)
        (and (>= next-x PARED-3-BLOQUEO-MIN-X)
              (<= next-x PARED-3-BLOQUEO-MAX-X))
        #false)

    ; Colisión con Pared 4 (Derecha de C1 - MÓVIL)
    (if (is-in-c1-block-wall-y-range? current-y current-c1-y)
        (and (>= next-x PARED-4-BLOQUEO-MIN-X)
              (<= next-x PARED-4-BLOQUEO-MAX-X))
        #false)
    ))

; A. Función de DIBUJO (to-draw)
(define (dibujar mundo)
  (cond
    ; ESCENA 1: MENÚ
    [(symbol=? (world-scene mundo) 'menu)
      (place-image FONDO-MENU
                      (/ BIG-BANG-WIDTH 2)
                      (/ BIG-BANG-HEIGHT 2)
                      (place-image PLAY-BUTTON
                                   PLAY-BUTTON-X
                                   PLAY-BUTTON-Y
                                   (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT)))]

    ; ESCENA 2: SELECCIÓN DE NIVEL
    [(symbol=? (world-scene mundo) 'seleccion-nivel)
      (let ([escena-base (place-image (text "Selecciona un Nivel" 40 "white")
                                      475 100 FONDO-SELECCION-NIVEL)])
        (place-image NIVEL-1-BUTTON NIVEL-1-X NIVEL-Y
                     (place-image NIVEL-2-BUTTON NIVEL-2-X NIVEL-Y
                                  (place-image NIVEL-3-BUTTON NIVEL-3-X NIVEL-Y
                                               escena-base))))]

    ; ESCENA 3: JUGANDO (Dibuja el nivel y el jugador)
    [(symbol=? (world-scene mundo) 'jugando)
      (cond
        ; NIVEL 1
        [(= (world-nivel-actual mundo) 1)
          (let* ([c1-y (world-cuadro-1-y mundo)]
                 [c2-y (world-cuadro-2-y mundo)]
                 [c3-y (world-cuadro-3-y mundo)]
                 ; La Y central de la plataforma móvil 1
                 [c1-visual-y (+ c1-y (/ CUADRO-1-HEIGHT 2))]
                 ; La Y central de la plataforma móvil 2
                 [c2-visual-y (+ c2-y (/ CUADRO-2-HEIGHT 2))]
                 ; La Y central de la plataforma móvil 3
                 [c3-visual-y (+ c3-y (/ CUADRO-3-HEIGHT 2))]
                 ; La Y central de las paredes laterales de C1 (Se mueve con c1-y)
                 [c1-bloqueo-y-center (+ c1-y (/ C1-BLOQUEO-HEIGHT 2))]

                 ; Dibuja el fondo y los botones
                 [escena-con-botones
                   (place-image RETURN-BUTTON
                                RETURN-BUTTON-X
                                RETURN-BUTTON-Y
                                FONDO-JUEGO)]

                 ; Dibuja la Plataforma 2 (Fija)
                 [escena-con-plataforma-2
                   (place-image PLATAFORMA-2-IMAGEN
                                PISO-2-X-CENTER
                                PISO-2-VISUAL-Y
                                escena-con-botones)]

                 ; Dibuja el Cuadro Móvil 1 (Morado - PELIGRO)
                 [escena-con-plataforma-1
                   (place-image PLATAFORMA-1-IMAGEN
                                CUADRO-1-X-CENTER
                                c1-visual-y
                                escena-con-plataforma-2)]

                 ; Dibuja el Cuadro Móvil 2 (Negro - MORTAL)
                 [escena-con-cuadro-2
                   (place-image PLATAFORMA-CUADRO-2-IMAGEN
                                CUADRO-2-X-CENTER
                                c2-visual-y
                                escena-con-plataforma-1)]

                 ; Dibuja el Cuadro Móvil 3 (Rojo - MORTAL)
                 [escena-con-cuadro-3
                   (place-image PLATAFORMA-CUADRO-3-IMAGEN
                                CUADRO-3-X-CENTER
                                c3-visual-y
                                escena-con-cuadro-2)]

                 ; Dibuja Pared de Bloqueo 1 (X=200, abajo P2 - Fija)
                 [escena-con-pared-1
                   (place-image PARED-BLOQUEO-IMAGEN
                                PARED-BLOQUEO-1-X
                                PARED-BLOQUEO-Y-CENTER
                                escena-con-cuadro-3)]

                 ; Dibuja Pared de Bloqueo 2 (X=750, abajo P2 - Fija)
                 [escena-con-pared-2
                   (place-image PARED-BLOQUEO-IMAGEN
                                PARED-BLOQUEO-2-X
                                PARED-BLOQUEO-Y-CENTER
                                escena-con-pared-1)]

                 ; Dibuja Pared de Bloqueo 3 (Izquierda de C1, X=200 - MÓVIL)
                 [escena-con-pared-3
                   (place-image C1-PARED-LATERAL-IMAGEN
                                PARED-BLOQUEO-3-X
                                c1-bloqueo-y-center
                                escena-con-pared-2)]

                 ; Dibuja Pared de Bloqueo 4 (Derecha de C1, X=350 - MÓVIL)
                 [escena-con-pared-4
                   (place-image C1-PARED-LATERAL-IMAGEN
                                PARED-BLOQUEO-4-X
                                c1-bloqueo-y-center
                                escena-con-pared-3)]

                 ; Dibuja la Puerta (META)
                 [escena-con-puerta
                   (place-image PUERTA-IMAGEN
                                PUERTA-X
                                PUERTA-Y
                                escena-con-pared-4)])

            ; Dibuja al jugador (Cuadrado amarillo)
            (place-image JUGADOR-IMAGEN
                          (world-jugador-x mundo)
                          (world-jugador-y mundo)
                          escena-con-puerta))]

        ; NIVEL 2
        [(= (world-nivel-actual mundo) 2)
          (let* ([escena-con-fondo
                   (place-image RETURN-BUTTON
                                RETURN-BUTTON-X
                                RETURN-BUTTON-Y
                                (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "darkslateblue"))]

                 ; Dibuja el piso principal
                 [escena-con-piso
                   (place-image N2-PISO-IMAGEN
                                (/ BIG-BANG-WIDTH 2)
                                N2-PISO-Y
                                escena-con-fondo)]

                 ; Dibuja la plataforma inicial izquierda (donde empieza el jugador)
                 [escena-con-plataforma-izq
                   (place-image N2-PLATAFORMA-INICIAL-IMAGEN
                                N2-PLATAFORMA-INICIAL-X-CENTER
                                N2-PLATAFORMA-INICIAL-Y-CENTER
                                escena-con-piso)]

                 ; Dibuja la plataforma derecha
                 [escena-con-plataforma-der
                   (place-image N2-PLATAFORMA-DERECHA-IMAGEN
                                N2-PLATAFORMA-DERECHA-X-CENTER
                                N2-PLATAFORMA-DERECHA-Y-CENTER
                                escena-con-plataforma-izq)]

                 ; Dibuja la escalera
                 [escena-con-escalera
                   (place-image N2-ESCALERA-IMAGEN
                                N2-ESCALERA-X-CENTER
                                N2-ESCALERA-Y-CENTER
                                escena-con-plataforma-der)]

                 ; Dibuja la puerta meta
                 [escena-con-puerta
                   (place-image N2-PUERTA-IMAGEN
                                N2-PUERTA-X
                                N2-PUERTA-Y
                                escena-con-escalera)])

            ; Dibuja al jugador
            (place-image JUGADOR-IMAGEN
                          (world-jugador-x mundo)
                          (world-jugador-y mundo)
                          escena-con-puerta))]

        [else (text "Nivel no implementado" 30 "red")])]

    ; ESCENA 4: MUERTO (¡Nueva pantalla de Game Over!)
    [(symbol=? (world-scene mundo) 'muerto)
      (let* ([game-over-text (text "¡APLASTADO!" 60 "red")]
             [restart-text (text "Presiona 'R' para Reiniciar el Nivel" 25 "white")]
             [background (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "black")]
             [escena-con-game-over (place-image game-over-text
                                                (/ BIG-BANG-WIDTH 2)
                                                (/ BIG-BANG-HEIGHT 2)
                                                background)])
        (place-image restart-text
                     (/ BIG-BANG-WIDTH 2)
                     (+ (/ BIG-BANG-HEIGHT 2) 50)
                     escena-con-game-over))]

    ; ESCENA 5: VICTORIA
    [(symbol=? (world-scene mundo) 'victoria)
      (let* ([victoria-text (text "¡NIVEL COMPLETADO!" 60 "gold")]
             [continuar-text (text "Presiona 'M' para volver al Menú" 25 "white")]
             [next-level-text (text "o 'N' para el Siguiente Nivel" 25 "lightgray")]
             [background (empty-scene BIG-BANG-WIDTH BIG-BANG-HEIGHT "darkblue")]
             [escena-con-victoria (place-image victoria-text
                                               (/ BIG-BANG-WIDTH 2)
                                               (/ BIG-BANG-HEIGHT 2)
                                               background)]
             [escena-con-continuar (place-image continuar-text
                                                (/ BIG-BANG-WIDTH 2)
                                                (+ (/ BIG-BANG-HEIGHT 2) 60)
                                                escena-con-victoria)])
        (place-image next-level-text
                     (/ BIG-BANG-WIDTH 2)
                     (+ (/ BIG-BANG-HEIGHT 2) 90)
                     escena-con-continuar))]

    [else (text "Error de Estado" 30 "red")]))


; B. Función de CLIC (on-mouse)
(define (manejar-click mundo x y evento)
  (if (mouse=? evento "button-down")
      (cond
        ; LÓGICA DE NAVEGACIÓN ENTRE ESCENAS
        [(symbol=? (world-scene mundo) 'menu)
          (if (es-click-en-boton? x y PLAY-BUTTON-X PLAY-BUTTON-Y BUTTON-WIDTH BUTTON-HEIGHT)
              ; TRANSICIÓN: MENU -> SELECCION DE NIVEL
              (make-world 'seleccion-nivel 0 0 0 0 0 0 0 0 0 0)
              mundo)]

        [(symbol=? (world-scene mundo) 'seleccion-nivel)
          (cond
            ; Clic en NIVEL 1: Carga el juego
            [(es-click-en-boton? x y NIVEL-1-X NIVEL-Y NIVEL-BUTTON-W NIVEL-BUTTON-H)
              ; TRANSICIÓN: SELECCION -> JUGANDO NIVEL 1
              (nivel-1-start-world)]

            ; Clic en NIVEL 2: Carga el nivel 2
            [(es-click-en-boton? x y NIVEL-2-X NIVEL-Y NIVEL-BUTTON-W NIVEL-BUTTON-H)
              ; TRANSICIÓN: SELECCION -> JUGANDO NIVEL 2
              (nivel-2-start-world)]

            ; Clic en NIVEL 3: Muestra mensaje
            [(es-click-en-boton? x y NIVEL-3-X NIVEL-Y NIVEL-BUTTON-W NIVEL-BUTTON-H)
              (displayln "Nivel 3 Próximamente")
              mundo]

            [else mundo])]

        [(symbol=? (world-scene mundo) 'jugando)
          (if (es-click-en-boton? x y RETURN-BUTTON-X RETURN-BUTTON-Y RETURN-BUTTON-W RETURN-BUTTON-H)
              ; TRANSICIÓN: JUGANDO -> MENU
              (make-world 'menu 0 0 0 0 0 0 0 0 0 0)
              mundo)]

        [else mundo])

      mundo))

; C. Función de TECLADO (on-key)
(define (manejar-tecla mundo tecla)
  (cond
    ; LÓGICA DE REINICIO
    [(and (symbol=? (world-scene mundo) 'muerto) (key=? tecla "r"))
      (if (= (world-nivel-actual mundo) 1)
          (nivel-1-start-world)
          (nivel-2-start-world))]

    ; LÓGICA DE VICTORIA
    [(symbol=? (world-scene mundo) 'victoria)
      (cond
        [(key=? tecla "m")
          (make-world 'menu 0 0 0 0 0 0 0 0 0 0)]
        [(key=? tecla "n")
          (displayln "Siguiente nivel próximamente")
          mundo]
        [else mundo])]

    ; LÓGICA DE JUEGO - NIVEL 1
    [(and (symbol=? (world-scene mundo) 'jugando) (= (world-nivel-actual mundo) 1))
      (let* (
            (current-x (world-jugador-x mundo))
            (current-y (world-jugador-y mundo))
            (current-vy (world-jugador-vy mundo))
            (current-c1-y (world-cuadro-1-y mundo))
            (current-c2-y (world-cuadro-2-y mundo))
            (current-c3-y (world-cuadro-3-y mundo))

            (piso-cuadro-1-y (- current-c1-y JUGADOR-HALF-HEIGHT))

            (can-jump? (and (= current-vy 0)
                            (or (>= current-y JUGADOR-Y-SUELO)
                                (= current-y PISO-2-Y)
                                (= current-y piso-cuadro-1-y))))

            (next-x (cond
                      [(key=? tecla "left") (- current-x JUGADOR-VELOCIDAD)]
                      [(key=? tecla "right") (+ current-x JUGADOR-VELOCIDAD)]
                      [else current-x]))

            (exterior-collision?
              (or (< next-x LIMITE-IZQ-CENTRO)
                  (> next-x LIMITE-DER-CENTRO)))

            (bloqueo-collision?
              (check-block-wall-collision? next-x current-y current-c1-y))

            (c1-top current-c1-y)
            (c1-bottom (+ current-c1-y CUADRO-1-HEIGHT))
            (player-top (- current-y JUGADOR-HALF-HEIGHT))
            (player-bottom (+ current-y JUGADOR-HALF-HEIGHT))

            (is-in-cuadro-1-y-range?
              (and (< player-top c1-bottom)
                    (> player-bottom c1-top)))

            (c1-lateral-collision?
              (if is-in-cuadro-1-y-range?
                  (and (>= next-x CUADRO-1-X-MIN-CENTER)
                        (<= next-x CUADRO-1-X-MAX-CENTER))
                  #false))

            (lateral-collision?
              (or exterior-collision?
                  bloqueo-collision?
                  c1-lateral-collision?))
            )

          (cond
            [(or (key=? tecla "up") (key=? tecla " "))
              (if can-jump?
                  (make-world 'jugando
                              (world-nivel-actual mundo)
                              current-x
                              current-y
                              JUMP-STRENGTH
                              (world-cuadro-1-y mundo)
                              (world-cuadro-1-dy mundo)
                              (world-cuadro-2-y mundo)
                              (world-cuadro-2-dy mundo)
                              (world-cuadro-3-y mundo)
                              (world-cuadro-3-dy mundo))
                  mundo)]

            [(or (key=? tecla "left") (key=? tecla "right"))
              (cond
                [lateral-collision?
                  mundo]
                [else
                  (make-world 'jugando
                              (world-nivel-actual mundo)
                              next-x
                              current-y
                              current-vy
                              (world-cuadro-1-y mundo)
                              (world-cuadro-1-dy mundo)
                              (world-cuadro-2-y mundo)
                              (world-cuadro-2-dy mundo)
                              (world-cuadro-3-y mundo)
                              (world-cuadro-3-dy mundo))])]

            [else mundo]))]

    ; LÓGICA DE JUEGO - NIVEL 2
    [(and (symbol=? (world-scene mundo) 'jugando) (= (world-nivel-actual mundo) 2))
      (let* (
            (current-x (world-jugador-x mundo))
            (current-y (world-jugador-y mundo))
            (current-vy (world-jugador-vy mundo))

            ; ¿Está en la escalera?
            (en-escalera? (esta-en-escalera? current-x current-y))

            ; Verificar si está en el suelo de la plataforma IZQUIERDA
            (en-plataforma-izquierda? (and (>= current-x N2-PLATAFORMA-INICIAL-X-START)
                                            (<= current-x N2-PLATAFORMA-INICIAL-X-END)
                                            (= current-y N2-PLATAFORMA-LANDING-Y)))

            ; Verificar si está en el suelo de la plataforma DERECHA
            (en-plataforma-derecha? (and (>= current-x N2-PLATAFORMA-DERECHA-X-START)
                                          (<= current-x N2-PLATAFORMA-DERECHA-X-END)
                                          (= current-y N2-PLATAFORMA-LANDING-Y)))

            ; Verificar si está en el piso principal
            (en-piso-principal? (= current-y (- N2-PISO-Y JUGADOR-HALF-HEIGHT)))

            (can-jump? (and (= current-vy 0)
                            (or en-plataforma-izquierda? 
                                en-plataforma-derecha?
                                en-piso-principal?)))

            (next-x (cond
                      [(key=? tecla "left") (- current-x JUGADOR-VELOCIDAD)]
                      [(key=? tecla "right") (+ current-x JUGADOR-VELOCIDAD)]
                      [else current-x]))

            ; Colisión con paredes exteriores
            (exterior-collision?
              (or (< next-x N2-LIMITE-IZQ-CENTRO)
                  (> next-x N2-LIMITE-DER-CENTRO)))

            ; Colisión LATERAL con la plataforma café IZQUIERDA
            (plat-izq-top N2-PLATAFORMA-INICIAL-Y-TOP)
            (plat-izq-bottom N2-PLATAFORMA-INICIAL-Y-BOTTOM)
            (player-top (- current-y JUGADOR-HALF-HEIGHT))
            (player-bottom (+ current-y JUGADOR-HALF-HEIGHT))

            (is-in-plataforma-izq-y-range?
              (and (< player-top plat-izq-bottom)
                   (> player-bottom plat-izq-top)))

            (plataforma-izq-lateral-collision?
              (if is-in-plataforma-izq-y-range?
                  (and (>= next-x N2-PLATAFORMA-X-MIN-CENTER)
                       (<= next-x N2-PLATAFORMA-X-MAX-CENTER))
                  #false))

            ; Colisión LATERAL con la plataforma café DERECHA
            (plat-der-top N2-PLATAFORMA-DERECHA-Y-TOP)
            (plat-der-bottom N2-PLATAFORMA-DERECHA-Y-BOTTOM)

            (is-in-plataforma-der-y-range?
              (and (< player-top plat-der-bottom)
                   (> player-bottom plat-der-top)))

            (plataforma-der-lateral-collision?
              (if is-in-plataforma-der-y-range?
                  (and (>= next-x N2-PLATAFORMA-DERECHA-X-MIN-CENTER)
                       (<= next-x N2-PLATAFORMA-DERECHA-X-MAX-CENTER))
                  #false))

            ; Colisión total lateral
            (lateral-collision?
              (or exterior-collision? 
                  plataforma-izq-lateral-collision?
                  plataforma-der-lateral-collision?))
            )

          (cond
            ; SUBIR EN LA ESCALERA (Presionar espacio mientras está en la escalera)
            [(and (or (key=? tecla "up") (key=? tecla " ")) en-escalera?)
              (let ([new-y (+ current-y N2-ESCALERA-CLIMB-SPEED)])
                ; Limitar el movimiento para no salirse por arriba
                (if (< new-y N2-ESCALERA-Y-TOP)
                    (make-world 'jugando
                                (world-nivel-actual mundo)
                                current-x
                                N2-ESCALERA-Y-TOP
                                0
                                0 0 0 0 0 0)
                    (make-world 'jugando
                                (world-nivel-actual mundo)
                                current-x
                                new-y
                                0 ; Velocidad 0 mientras sube
                                0 0 0 0 0 0)))]

            ; SALTAR (solo si no está en la escalera)
            [(and (or (key=? tecla "up") (key=? tecla " ")) can-jump? (not en-escalera?))
              (make-world 'jugando
                          (world-nivel-actual mundo)
                          current-x
                          current-y
                          JUMP-STRENGTH
                          0 0 0 0 0 0)]

            [(or (key=? tecla "left") (key=? tecla "right"))
              (if lateral-collision?
                  mundo
                  (make-world 'jugando
                              (world-nivel-actual mundo)
                              next-x
                              current-y
                              current-vy
                              0 0 0 0 0 0))]

            [else mundo]))]

    [else mundo]))

; D. Función de TICKS (on-tick)
(define (manejar-tick mundo)
  (cond
    ; NIVEL 1
    [(and (symbol=? (world-scene mundo) 'jugando) (= (world-nivel-actual mundo) 1))
      (let* (
        (jugador-x (world-jugador-x mundo))
        (old-y (world-jugador-y mundo))
        (current-vy (world-jugador-vy mundo))
        (cuadro-1-y (world-cuadro-1-y mundo))
        (cuadro-1-dy (world-cuadro-1-dy mundo))
        (cuadro-2-y (world-cuadro-2-y mundo))
        (cuadro-2-dy (world-cuadro-2-dy mundo))
        (cuadro-3-y (world-cuadro-3-y mundo))
        (cuadro-3-dy (world-cuadro-3-dy mundo))

        ; Movimiento de Cuadro 1
        (next-c1-y (+ cuadro-1-y cuadro-1-dy))
        (next-c1-dy (cond
                      [(and (<= next-c1-y CUADRO-1-Y-MIN) (< cuadro-1-dy 0)) CUADRO-1-SPEED]
                      [(and (>= next-c1-y CUADRO-1-Y-MAX) (> cuadro-1-dy 0)) (- CUADRO-1-SPEED)]
                      [else cuadro-1-dy]))
        (new-cuadro-1-y (+ cuadro-1-y next-c1-dy))
        (y-change-1 (- new-cuadro-1-y cuadro-1-y))

        ; Movimiento de Cuadro 2
        (next-c2-y (+ cuadro-2-y cuadro-2-dy))
        (next-c2-dy (cond
                      [(and (<= next-c2-y CUADRO-2-Y-MIN) (< cuadro-2-dy 0)) CUADRO-2-SPEED]
                      [(and (>= next-c2-y CUADRO-2-Y-MAX) (> cuadro-2-dy 0)) (- CUADRO-2-SPEED)]
                      [else cuadro-2-dy]))
        (new-cuadro-2-y (+ cuadro-2-y next-c2-dy))

        ; Movimiento de Cuadro 3
        (next-c3-y (+ cuadro-3-y cuadro-3-dy))
        (next-c3-dy (cond
                      [(and (<= next-c3-y CUADRO-3-Y-MIN) (< cuadro-3-dy 0)) CUADRO-3-SPEED]
                      [(and (>= next-c3-y CUADRO-3-Y-MAX) (> cuadro-3-dy 0)) (- CUADRO-3-SPEED)]
                      [else cuadro-3-dy]))
        (new-cuadro-3-y (+ cuadro-3-y next-c3-dy))

        (C1-BOTTOM-EDGE (+ new-cuadro-1-y CUADRO-1-HEIGHT))
        (piso-cuadro-1-y (- cuadro-1-y JUGADOR-HALF-HEIGHT))
        (piso-cuadro-1-y-next (- new-cuadro-1-y JUGADOR-HALF-HEIGHT))

        (player-was-resting-on-c1?
          (and (esta-en-cuadro-1-rango-con-margen? jugador-x)
                (= old-y piso-cuadro-1-y)))

        (adjusted-old-y (if player-was-resting-on-c1?
                            (+ old-y y-change-1)
                            old-y))

        (is-resting-p1? (and (= adjusted-old-y JUGADOR-Y-SUELO) (= current-vy 0)))
        (is-resting-p2? (and (= adjusted-old-y PISO-2-Y) (= current-vy 0)))

        (should-start-fall-p2?
          (and is-resting-p2?
                (not (esta-en-rango-con-margen? jugador-x))))

        (should-start-fall-c1?
          (and player-was-resting-on-c1?
                (not (esta-en-cuadro-1-rango-con-margen? jugador-x))))

        (should-start-fall? (or should-start-fall-p2? should-start-fall-c1?))

        (should-stay-at-rest?
          (and (or is-resting-p1? is-resting-p2? player-was-resting-on-c1?)
                (not should-start-fall?)))

        (y-at-rest (cond
                      [player-was-resting-on-c1? piso-cuadro-1-y-next]
                      [is-resting-p2? PISO-2-Y]
                      [is-resting-p1? JUGADOR-Y-SUELO]
                      [else adjusted-old-y]))

        (vy-initial (if should-start-fall?
                        GRAVITY
                        current-vy))

        (nueva-vy (+ vy-initial GRAVITY))
        (nueva-y (+ adjusted-old-y nueva-vy))

        (head-bump-p2?
          (and (< current-vy 0)
                (esta-en-rango-con-margen? jugador-x)
                (<= (- nueva-y JUGADOR-HALF-HEIGHT)
                    PLATAFORMA-BOTTOM)
                (> (- adjusted-old-y JUGADOR-HALF-HEIGHT)
                    PLATAFORMA-BOTTOM)))

        (head-bump-c1?
          (and (< current-vy 0)
                (esta-en-cuadro-1-rango? jugador-x)
                (<= (- nueva-y JUGADOR-HALF-HEIGHT) C1-BOTTOM-EDGE)
                (> (- adjusted-old-y JUGADOR-HALF-HEIGHT) C1-BOTTOM-EDGE)))

        (head-bump? (or head-bump-p2? head-bump-c1?))

        (en-suelo-principal? (>= nueva-y JUGADOR-Y-SUELO))

        (aterrizando-en-plataforma-2?
          (and (esta-en-rango-con-margen? jugador-x)
                (< adjusted-old-y PISO-2-Y)
                (>= nueva-y PISO-2-Y)))

        (aterrizando-en-cuadro-1?
          (and (esta-en-cuadro-1-rango-con-margen? jugador-x)
                (< adjusted-old-y piso-cuadro-1-y-next)
                (>= nueva-y piso-cuadro-1-y-next)))

        (vy-stop? (or aterrizando-en-plataforma-2?
                      en-suelo-principal?
                      head-bump?
                      aterrizando-en-cuadro-1?))

        (y-final-normal (cond
                          [head-bump-p2?
                            (+ PLATAFORMA-BOTTOM JUGADOR-HALF-HEIGHT)]
                          [head-bump-c1?
                            (+ C1-BOTTOM-EDGE JUGADOR-HALF-HEIGHT)]
                          [aterrizando-en-cuadro-1? piso-cuadro-1-y-next]
                          [aterrizando-en-plataforma-2? PISO-2-Y]
                          [en-suelo-principal? JUGADOR-Y-SUELO]
                          [else nueva-y]))

        (vy-final-normal (if vy-stop? 0 nueva-vy))
      )

      ; Primero verifica si el jugador llegó a la puerta (VICTORIA)
      (if (jugador-en-puerta? jugador-x y-final-normal)
          (make-world 'victoria
                      (world-nivel-actual mundo)
                      jugador-x
                      y-final-normal
                      0
                      new-cuadro-1-y
                      next-c1-dy
                      new-cuadro-2-y
                      next-c2-dy
                      new-cuadro-3-y
                      next-c3-dy)

          ; Si no llegó a la puerta, verifica si murió
          (if (is-deadly-collision? jugador-x y-final-normal new-cuadro-1-y new-cuadro-2-y new-cuadro-3-y)
              (make-world 'muerto
                          (world-nivel-actual mundo)
                          jugador-x
                          y-final-normal
                          0
                          new-cuadro-1-y
                          next-c1-dy
                          new-cuadro-2-y
                          next-c2-dy
                          new-cuadro-3-y
                          next-c3-dy)

              ; Si no murió, continúa el movimiento normal
              (cond
                [should-stay-at-rest?
                  (make-world 'jugando
                              (world-nivel-actual mundo)
                              jugador-x
                              y-at-rest
                              0
                              new-cuadro-1-y
                              next-c1-dy
                              new-cuadro-2-y
                              next-c2-dy
                              new-cuadro-3-y
                              next-c3-dy)]

                [else
                  (make-world 'jugando
                              (world-nivel-actual mundo)
                              jugador-x
                              y-final-normal
                              vy-final-normal
                              new-cuadro-1-y
                              next-c1-dy
                              new-cuadro-2-y
                              next-c2-dy
                              new-cuadro-3-y
                              next-c3-dy)]))))]

    ; NIVEL 2
    [(and (symbol=? (world-scene mundo) 'jugando) (= (world-nivel-actual mundo) 2))
      (let* (
        (jugador-x (world-jugador-x mundo))
        (old-y (world-jugador-y mundo))
        (current-vy (world-jugador-vy mundo))

        ; ¿Está en la escalera?
        (en-escalera? (esta-en-escalera? jugador-x old-y))

        ; Verificar si está horizontalmente sobre la plataforma café IZQUIERDA
        (esta-sobre-plataforma-izq-x?
          (and (>= jugador-x N2-PLATAFORMA-INICIAL-X-START)
               (<= jugador-x N2-PLATAFORMA-INICIAL-X-END)))

        ; Verificar si está horizontalmente sobre la plataforma café DERECHA
        (esta-sobre-plataforma-der-x?
          (and (>= jugador-x N2-PLATAFORMA-DERECHA-X-START)
               (<= jugador-x N2-PLATAFORMA-DERECHA-X-END)))

        ; Verificar si está sobre CUALQUIERA de las dos plataformas
        (esta-sobre-alguna-plataforma-x?
          (or esta-sobre-plataforma-izq-x? esta-sobre-plataforma-der-x?))

        ; ¿Está descansando en alguna plataforma café? (velocidad 0 y en la posición correcta)
        (is-resting-on-plataforma?
          (and (= old-y N2-PLATAFORMA-LANDING-Y)
               (= current-vy 0)
               esta-sobre-alguna-plataforma-x?))

        ; ¿Está descansando en el piso principal?
        (is-resting-on-piso?
          (and (= old-y (- N2-PISO-Y JUGADOR-HALF-HEIGHT))
               (= current-vy 0)))

        ; Si está en la escalera, NO aplicar gravedad
        ; Si está descansando, debe quedarse quieto (no aplicar gravedad)
        (should-stay-at-rest? (or is-resting-on-plataforma? is-resting-on-piso? en-escalera?))

        ; Aplicar gravedad solo si no está en reposo NI en la escalera
        (nueva-vy (if should-stay-at-rest? 0 (+ current-vy GRAVITY)))
        (nueva-y (if should-stay-at-rest? old-y (+ old-y nueva-vy)))

        ; Verificar aterrizaje en plataformas (cayendo desde arriba)
        (aterrizando-en-plataforma-inicial?
          (and esta-sobre-alguna-plataforma-x?
               (> current-vy 0) ; Está cayendo
               (< old-y N2-PLATAFORMA-LANDING-Y) ; Estaba arriba
               (>= nueva-y N2-PLATAFORMA-LANDING-Y))) ; Ahora está en o debajo

        ; Verificar si debe CAERSE de la plataforma (se movió fuera del rango)
        (should-fall-from-plataforma?
          (and (= old-y N2-PLATAFORMA-LANDING-Y)
               (= current-vy 0)
               (not esta-sobre-alguna-plataforma-x?)))

        ; Verificar aterrizaje en piso principal
        (aterrizando-en-piso?
          (and (>= nueva-y (- N2-PISO-Y JUGADOR-HALF-HEIGHT))))

        ; Verificar golpe de cabeza INFERIOR de alguna plataforma café
        (head-bump-plataforma?
          (and (< current-vy 0) ; Subiendo
               esta-sobre-alguna-plataforma-x?
               (<= (- nueva-y JUGADOR-HALF-HEIGHT) N2-PLATAFORMA-INICIAL-Y-BOTTOM)
               (> (- old-y JUGADOR-HALF-HEIGHT) N2-PLATAFORMA-INICIAL-Y-BOTTOM)))

        (y-final (cond
                   [should-stay-at-rest? old-y] ; Mantener posición si está en reposo o en escalera
                   [head-bump-plataforma? (+ N2-PLATAFORMA-INICIAL-Y-BOTTOM JUGADOR-HALF-HEIGHT)]
                   [aterrizando-en-plataforma-inicial? N2-PLATAFORMA-LANDING-Y]
                   [aterrizando-en-piso? (- N2-PISO-Y JUGADOR-HALF-HEIGHT)]
                   [else nueva-y]))

        (vy-final (cond
                    [should-stay-at-rest? 0] ; Velocidad 0 si está en reposo o en escalera
                    [should-fall-from-plataforma? GRAVITY] ; Empezar a caer
                    [(or aterrizando-en-plataforma-inicial? 
                         aterrizando-en-piso?
                         head-bump-plataforma?) 0]
                    [else nueva-vy]))
        )

        ; Verificar victoria en Nivel 2
        (if (jugador-en-puerta-n2? jugador-x y-final)
            (make-world 'victoria
                        (world-nivel-actual mundo)
                        jugador-x
                        y-final
                        0
                        0 0 0 0 0 0)
            (make-world 'jugando
                        (world-nivel-actual mundo)
                        jugador-x
                        y-final
                        vy-final
                        0 0 0 0 0 0)))]

    [else mundo]))

; ====================================================
; 5. EL MOTOR DEL JUEGO (BIG-BANG)
; ====================================================

(define MUNDO-INICIAL
  (make-world 'menu 0 0 0 0 0 0 0 0 0 0))

(big-bang MUNDO-INICIAL
  [name "Inspector Blindson - Plataformas"]
  [to-draw dibujar]
  [on-mouse manejar-click]
  [on-key manejar-tecla]
  [on-tick manejar-tick TICK-RATE]
  [stop-when (lambda (mundo) #false)])