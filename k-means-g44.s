#
# IAC 2023/2024 k-means
# 
# Grupo: 44
# Campus: Alameda
#
# Autores:
# 110008, Bernardo Sousa
# 110130, Diogo Callado
# 110020, Diogo Pan
#
# Tecnico/ULisboa


# ALGUMA INFORMACAO ADICIONAL PARA CADA GRUPO:
# - A "LED matrix" deve ter um tamanho de 32 x 32
# - O input e' definido na seccao .data. 
# - Abaixo propomos alguns inputs possiveis. Para usar um dos inputs propostos, basta descomentar 
#   esse e comentar os restantes.
# - Encorajamos cada grupo a inventar e experimentar outros inputs.
# - Os vetores points e centroids estao na forma x0, y0, x1, y1, ...


# Variaveis em memoria
.data

#Input A - linha inclinada
#n_points:    .word 9
#points:      .word 0,0, 1,1, 2,2, 3,3, 4,4, 5,5, 6,6, 7,7 8,8

#Input B - Cruz
#n_points:    .word 5
#points:     .word 4,2, 5,1, 5,2, 5,3 6,2

#Input C
#n_points:    .word 23
#points: .word 0,0, 0,1, 0,2, 1,0, 1,1, 1,2, 1,3, 2,0, 2,1, 5,3, 6,2, 6,3, 6,4, 7,2, 7,3, 6,8, 6,9, 7,8, 8,7, 8,8, 8,9, 9,7, 9,8

#Input D
n_points:    .word 30
points:      .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10



# Valores de centroids e k a usar na 1a parte do projeto:
#centroids:   .word 0,0
#k:           .word 1

# Valores de centroids, k e L a usar na 2a parte do prejeto:
centroids:   .word 0,0, 10,0, 0,10
k:           .word 3
L:           .word 10

# Abaixo devem ser declarados o vetor clusters (2a parte) e outras estruturas de dados
# que o grupo considere necessarias para a solucao:
clusters:    .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0




# Definicoes de cores a usar no projeto 

colors:      .word 0xff0000, 0x00ff00, 0x0000ff  # Cores dos pontos do cluster 0, 1, 2, etc.

.equ         black      0
.equ         white      0xffffff



# Codigo
 
.text
    # Chama funcao principal da 1a parte do projeto
    #jal mainSingleCluster

    # Descomentar na 2a parte do projeto:
    jal mainKMeans
    
    #Termina o programa (chamando chamada sistema)
    li a7, 10
    ecall


### printPoint
# Pinta o ponto (x,y) na LED matrix com a cor passada por argumento
# Nota: a implementacao desta funcao ja' e' fornecida pelos docentes
# E' uma funcao auxiliar que deve ser chamada pelas funcoes seguintes que pintam a LED matrix.
# Argumentos:
# a0: x
# a1: y
# a2: cor

printPoint:
    li a3, LED_MATRIX_0_HEIGHT
    sub a1, a3, a1
    addi a1, a1, -1
    li a3, LED_MATRIX_0_WIDTH
    mul a3, a3, a1
    add a3, a3, a0
    slli a3, a3, 2
    li a0, LED_MATRIX_0_BASE
    add a3, a3, a0   # addr
    sw a2, 0(a3)
    jr ra
    

### cleanScreen
# Limpa todos os pontos do ecra
# Argumentos: nenhum
# Retorno: nenhum

cleanScreen:
    # OPTIMIZATION
    # Mudou-se o armazenamento do registo "ra" na memoria para o inicio da funcao e restauracao para o final.
    # Removeu-se o armazenamento e restauracao dos registos "a0" e "a1" da memoria, uma vez que nao eram necessarios.
    # A restauracao do registo "a0" (coordenada x do ponto a ser limpo) eh feita copiando do contador.
    # Melhora a eficiencia da memoria, 
    # nao necessitando guardar e restaurar a cada loop interior, resultando em menos acessos ah memoria.
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, LED_MATRIX_0_WIDTH    # Contador decrescente da coordenada x  
    li a2, white
x_loop:
    # OPTIMIZATION
    # Criou-se um contador crescente para a coordenada y, limpando o ecra de duas direcoes em simultaneo.
    # Melhora a eficiencia de desempenho da funcao, reduzindo pela metade o numero necessario de loops interiores.
    li t1, LED_MATRIX_0_HEIGHT    # Contador decrescente da coordenada y superior
    li t2, 0    # Contador crescente coordenada y inferior
    addi t0, t0, -1
    blt t0, x0, end_cleanScreen
    add a0, x0, t0    # Coordenada x do loop exterior atual
y_loop:
    addi t1, t1, -1
    blt t1, t2, x_loop    # Se as duas coordenadas passarem entre elas
    mv a0, t0    # Repoe a coordenada x
    mv a1, t1    # Coordenada y superior
    jal printPoint    # Limpa as coordenadas supeiores
    mv a0, t0    # Repoe a coordenada x
    mv a1, t2    # Coordenada y inferior
    jal printPoint    # Limpa as coordenadas inferiores
    addi t2, t2, 1
    j y_loop
end_cleanScreen:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

    
### printClusters
# Pinta os agrupamentos na LED matrix com a cor correspondente.
# Argumentos: nenhum
# Retorno: nenhum

# Changes: Mudou-se alguns registos usados na 1a parte para conseguir implementar a 2a parte do projeto
printClusters:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, colors
    lw t1, n_points    # Quantidade de pontos no vetor dos pontos
    la t2, points
    la t3, clusters
    li t4, 1    # Valor de comparacao com k
    lw t5, k
    bgt t5, t4, loop_points_not_k1    # Caso k seja maior que 1
    lw a2, 0(t0)    # Cor para os pontos com k=1
loop_points_k1:
    beq t1, x0, end_printClusters    # Se percorreu todos os pontos
    addi t1, t1, -1
    lw a0, 0(t2)    # Coordenada x
    lw a1, 4(t2)    # Coordenada y
    addi t2, t2, 8    # Endereco do inicio da proxima coordenada
    jal printPoint
    j loop_points_k1
loop_points_not_k1:
    beq t1, x0, end_printClusters
    lw a0, 0(t2)    # Coordenada x
    lw a1, 4(t2)    # Coordenada y
    lw t4, 0(t3)    # Busca o cluster a que pertence o ponto atual
    slli t4, t4, 2    # Offset para a busca no vetor das cores
    add t0, t0, t4
    lw t6, 0(t0)    # Cor do cluster
    add a2, x0, t6
    jal printPoint
    sub t0, t0, t4    # Repoe o endereco do vetor das cores
    addi t1, t1, -1    # Menos um ponto ja impresso
    addi t2, t2, 8    # Incremento para o endereco do proximo ponto
    addi t3, t3, 4    # Incremento para o endereco do cluster do proximo ponto
    j loop_points_not_k1
end_printClusters:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


### printCentroids
# Pinta os centroides na LED matrix
# Nota: deve ser usada a cor preta (black) para todos os centroides
# Argumentos: nenhum
# Retorno: nenhum

printCentroids:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, centroids
    lw t1, k
    la t2, colors
loop_printCentroids:
    beq t1, x0, end_printCentroids    # Se ja percorreu por todos os centroids
    lw a0, 0(t0)    # Coordenada x
    lw a1, 4(t0)    # Coordenada y
    lw a2, 0(t2)    # Cor do centroid
    jal printPoint
    addi t0, t0, 8    # Incremento para o endereco do proximo ponto
    addi, t2, t2, 4
    addi t1, t1, -1
    j loop_printCentroids
end_printCentroids:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
    

### calculateCentroids
# Calcula os k centroides, a partir da distribuicao atual de pontos associados a cada agrupamento (cluster)
# e compara se os centroids anteriores foram alterados
# Argumentos: nenhum
# Retorno: 1 se centroids forem alterados, 0 caso contrario

# Changes: Mudou-se alguns registos usados na 1a parte para conseguir implementar a 2a parte do projeto.
# Alterou-se a funcionalidade da funcao, analisando se algum centroid foi alterado com o calculo dos novos centroids.
# Esta alteracao permite agilizar o processo de comparacao e o desempenho do algoritmo k-means, 
# sem ter que criar novas funcoes e possivelmente varios acessos repetitivos ah memoria.
calculateCentroids:
    lw t0, k
    li t1, 0    # Soma total das coordenadas x
    li t2, 0    # Soma total das coordenadas y
    lw t3, n_points    # Quantidade de pontos
    la t4, points
    li a0, 0    # Flag de alteracao de centroid
    la a1, clusters
    li a2, 0    # Contador do numero de pontos pertencentes ao mesmo cluster
    addi t0, t0, -1    # Primeiro cluster (indice do ultimo centroid)
    bgt t0, x0, loop_cluster_sum    # Caso k seja maior que 0 (valor inicial maior que 1)
    lw a2, n_points    # Usado no calculo da media caso k=1
loop_all_sum:
    beq t3, x0, calculate_save    # Se percorreu todos os pontos
    addi t3, t3, -1
    lw t5, 0(t4)    # Coordenada x
    lw t6, 4(t4)    # Coordenada y
    add t1, t1, t5
    add t2, t2, t6
    addi t4, t4, 8    # Incremento para o endereco do proximo ponto
    j loop_all_sum
loop_cluster_sum:
    beq t3, x0, calculate_save    # Se percorreu todos os pontos
    addi t3, t3, -1
    lw t5, 0(t4)    # Coordenada x
    lw t6, 4(t4)    # Coordenada y
    lw a3, 0(a1)    # Cluster associado ao ponto atual
    bne t0, a3, next_point    # Caso ponto atual nao pertencer ao cluster atual
    add t1, t1, t5
    add t2, t2, t6
    addi a2, a2, 1
next_point:
    addi t4, t4, 8    # Incremento para o endereco do proximo ponto
    addi a1, a1, 4    # Incremento para o endereco do cluster do proximo ponto
    j loop_cluster_sum
calculate_save:
    beq a2, x0, resets    # Se nao existirem pontos que pertencam ao cluster atual
    div t1, t1, a2    # Calcula coordenada x do centroid
    div t2, t2, a2    # Calcula coordenada y do centroid
    slli t4, t0, 3    # Offset para guardar as coordenadas do centroid calculado no vetor dos centroids
    la t5, centroids
    add t5, t5, t4
    lw t3, 0(t5)
    lw t4, 4(t5)
    # Caso nao houver mudancas nas coordenadas do centroid calculado com o anterior
    beq t1, t3, resets
    beq t2, t4, resets
    addi a0, x0, 1    # Coloca a flag a 1 (houve mudanca)
    sw t1, 0(t5)
    sw t2, 4(t5)
resets:
    addi t0, t0, -1    # Proximo cluster
    li t1, 0    # Repoe a soma total das coordenadas x
    li t2, 0    # Repoe a soma total das coordenadas y
    lw t3, n_points    # Repoe a quantidade de pontos
    la t4, points    # Repoe o endereco inicial do vetor dos pontos
    la a1, clusters    # Repoe o endereco do vetor de clusters
    li a2, 0    # Repoe o contador de pontos do mesmo cluster
    bge t0, x0, loop_cluster_sum    # Caso indice do proximo centroid que ira ser calculado for maior ou igual a 0
    jr ra


### mainSingleCluster
# Funcao principal da 1a parte do projeto.
# Argumentos: nenhum
# Retorno: nenhum

mainSingleCluster:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    #1. Coloca k=1 (caso nao esteja a 1)
    la t0, k
    li t1, 1
    sw t1, 0(t0)
    
    #2. cleanScreen
    jal cleanScreen

    #3. printClusters
    jal printClusters

    #4. calculateCentroids
    jal calculateCentroids

    #5. printCentroids
    jal printCentroids

    #6. Termina
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


### initializeCentroids
# Inicializa os valores iniciais do vetor centroids
# Argumentos: nenhum
# Retorno: nenhum

initializeCentroids:
    li a7, 30
    ecall    # Obter tempo no registo a0 e a1
    lw t0, k    # Numero de centroids
    slli t0, t0, 1    # Numero total de coordenadas (soma da quantidade de coordenadas x e y)
    li t1, 0    # Inicializa o contador das coordenadas ja inicializadas
    li t2, 1103515245    # Multiplicador
    li t3, 12345    # Incremento
    li t4, LED_MATRIX_0_HEIGHT # Mod
    la t5, centroids
loop_random_gen:
    beq t1, t0, end_initializeCentroids    # Se o numero de coordenadas inicializadas for completo
    mul a0, a0, t2    # x(n) * 1103515245
    add a0, a0, t3    # Anterior + 12345
    bge a0, x0, not_negative    # Caso a0 for negativo
    neg a0, a0
not_negative:
    rem t6, a0, t4    # Total mod Height(32)
    sw t6, 0(t5)
    addi t1, t1, 1
    addi t5, t5, 4    # Incremento do endereco para a proxima coordenada
    j loop_random_gen
end_initializeCentroids:
    jr ra  
    

### manhattanDistance
# Calcula a distancia de Manhattan entre (x0,y0) e (x1,y1)
# Argumentos:
# a0, a1: x0, y0
# a2, a3: x1, y1
# Retorno:
# a0: distance

manhattanDistance:
    sub a0, a0, a2
    sub a1, a1, a3
    bge a0, x0, check_negative_y    # Se resultado de x0-x1 for positivo
    neg a0, a0
check_negative_y:
    bge a1, x0, end_manhattanDistance    # Se resultado de y0-y1 for positivo
    neg a1, a1
end_manhattanDistance:
    add a0, a0, a1    # Resultado do calculo da distancia
    jr ra


### nearestCluster
# Determina o centroide mais perto de um dado ponto (x,y).
# Argumentos:
# a0, a1: (x, y) point
# Retorno:
# a0: cluster index

nearestCluster:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, centroids
    lw t1, k    # Numero total de centroids
    li t2, 0x7ff    # Inicializa a menor distancia do centroid ao ponto
    li t3, 0    # Inicializa o contador/indice do vetor de centroids
loop_check_nearest:
    beq t1, t3, end_nearestCluster    # Se passar por todos os centroids
    addi sp, sp, -8
    sw a0, 0(sp)
    sw a1, 4(sp)
    lw a2, 0(t0)    # Coordenada x do centroid com indice t1
    lw a3, 4(t0)    # Coordenada y do centroid com indice t1
    jal manhattanDistance    # Calcula distancia entre o centroid com indice atual (t1) e o ponto
    bge a0, t2, not_lower    # Se a distancia calculada nao for menor que a distancia anterior
    mv t2, a0    # Guarda a menor distancia atual
    mv t4, t3    # Guarda o indice do centroid atual de menor distancia ao ponto
not_lower:
    lw a0, 0(sp)
    lw a1, 4(sp)
    addi sp, sp, 8
    addi t3, t3, 1
    addi t0, t0, 8    # Incremento do endereco para a proxima coordenada
    j loop_check_nearest
end_nearestCluster:
    mv a0, t4    # Move o indice do centroid com menor distancia ao ponto para o registo de retorno
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


### mainKMeans
# Executa o algoritmo *k-means*.
# Argumentos: nenhum
# Retorno: nenhum

mainKMeans:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal initializeCentroids    #Inicializa pseudo-aleatoriamente o vetor centroids
    jal attributeClusters    # Preenche o vetor clusters com clusters de cada ponto
    lw t0, L
    li a0, 1
loop_main:
    beq t0, x0, end_main    # Se ja forem feitos L loops
    addi sp, sp, -4
    sw t0, 0(sp)
    
    jal calculateCentroids    # Calcula os centroids verdadeiros de cada cluster
    addi sp, sp, -4
    sw a0, 0(sp)
    
    jal attributeClusters    # Preenche o vetor clusters com clusters de cada ponto
    
    jal cleanScreen    # Limpa o ecra no inicio de cada iteracao
    
    jal printClusters    # Pinta todos os clusters
    
    jal printCentroids    # Pinta todos os centroides
    
    lw a0, 0(sp)
    lw t0, 4(sp)
    addi sp, sp, 8
    addi t0, t0, -1
    beq a0, x0, end_main    # Caso nao haja mudancas nos centroids
    j loop_main
end_main:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


### attributeClusters (Funcao auxiliar)
# Atribui um cluster a todos os pontos
# Argumentos: nenhum
# Retorno: nenhum

attributeClusters:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw t0, n_points
    la t1, clusters
    la t2, points
loop:
    beq t0, x0, end_attribute    # Se ja for atribuido um cluster a cada ponto
    addi t0, t0, -1 
    lw a0, 0(t2)    # Coordenada x
    lw a1, 4(t2)    # Coordenada y
    addi sp, sp, -12
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    jal nearestCluster
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 12
    addi t2, t2, 8    # Proximo ponto
    sw a0, 0(t1)
    addi t1, t1, 4    # Endereco do cluster do proximo ponto
    j loop
end_attribute:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
