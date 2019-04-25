/*********************************************
 * OPL 12.8.0.0 Model
 * Author: joaon
 * Creation Date: 04/12/2018 at 16:24:34
 *********************************************/
int n=...; 	//dimens�o da matriz, 7
int vN[1..n][1..n]=...; //valores dos tempos de propaga��o sentido Norte
int vS[1..n][1..n]=...; //valores dos tempos de propaga��o sentido Sul
int vW[1..n][1..n]=...; //valores dos tempos de propaga��o sentido Oeste
int vE[1..n][1..n]=...; //valores dos tempos de propaga��o sentido Este
int Delta = 8; //delay adicional � propaga��o quando existe equipa de bombeiros
int b = 8; //n� de recursos m�ximo
int time = 12; //tempo para simular o fogo
float probIgni[1..n][1..n]; // probabilidades de igni��o na c�lula (i,j)

dvar boolean equipas[1..n][1..n]; //quantas equipas na c�lula (x,y)
dvar boolean ardido[1..n][1..n][1..n][1..n]; //c�lulas (x,y) ardidas quando houve igni��o em (i,j)
dvar float+ Tempos[1..n][1..n][1..n][1..n]; //matriz de tempos de propaga��o runtime, para cada igni��o na c�lula (i,j) guarda os tempos de propaga��o at� (x,y)

execute{ //instanciar as probabilidades
	for(var i=1;i<=n;i++){
		for(var j=1;j<=n;j++){
			probIgni[i][j]=(14-i-j)/500;
 		}				
	}
}

/*
Os tempos de propaga��o s�o calculados desde a c�lula [i][j] onde come�a o inc�ndio
Para termos uma estimativa do caso gen�rico, temos de fazer uma m�dia dos tempos para todos os locais de inc�ndio poss�veis, ponderados com
a probabilidade de igni��o nessa c�lula  

zik <-> tik se <=12
zik = ardido? para a c�lula i se teve igni��o na c�lula k

x,i vertical |; y,j horizontal --; linhas e colunas da matriz
*/
minimize sum(i in 1..n, j in 1..n) probIgni[i][j]*sum (x in 1..n, y in 1..n) ardido[i][j][x][y]; //minimizar �rea ardida

subject to{ 
	sum 	(i in 1..n, j in 1..n) equipas[i][j] == b; 		//total de equipas dispon�veis n�o superior a b
	//estamos a tentar maximizar os tempos (abrandar o fogo), o fogo propaa pelos caminhos mais curtos. O rate of fire spread ROS n�o � dado, por isso assume-se 1.
	forall  (i in 1..n, j in 1..n, x in 2..n, y in 1..n) 	Tempos[i][j][x-1][y] <= Tempos[i][j][x][y] + vN[x][y] + Delta*equipas[x][y]; //tempo de propaga��o de (x,y) para a c�lula adjacente a Norte (x-1)
    forall  (i in 1..n, j in 1..n, x in 1..n-1, y in 1..n)	Tempos[i][j][x+1][y] <= Tempos[i][j][x][y] + vS[x][y] + Delta*equipas[x][y]; //tempo de propaga��o de (x,y) para a c�lula adjacente a Sul	(x+1)
    forall  (i in 1..n, j in 1..n, x in 1..n, y in 2..n) 	Tempos[i][j][x][y-1] <= Tempos[i][j][x][y] + vW[x][y] + Delta*equipas[x][y]; //tempo de propaga��o de (x,y) para a c�lula adjacente a Oeste	(y-1)
    forall  (i in 1..n, j in 1..n, x in 1..n, y in 1..n-1)	Tempos[i][j][x][y+1] <= Tempos[i][j][x][y] + vE[x][y] + Delta*equipas[x][y]; //tempo de propaga��o de (x,y) para a c�lula adjacente a Este	(y+1)
  
    //Tempos[s][s] = 0 para todos os pontos de igni��o s
    forall  (i in 1..n, j in 1..n) 	Tempos[i][j][i][j] == 0; //local de igni��o, for�a o valor 0. Quando estams a analisar com um dos 49 pontos de igni��o (i,j), esse tempo deve ser 0 ERRO 
        
    //como est�mos a minimizar ardido, o soler coloca Tempos=12 em todo o lado, para anular o time, e assim minimizar o ardido.
    forall  (i in 1..n, j in 1..n, x in 1..n, y in 1..n) 	ardido[i][j][x][y] 	>= (time-Tempos[i][j][x][y])/time; // se chegou l� antes dos 12 segundos, ardeu. Testa todo o mapa para cada igni��o (i,j)poss�vel
    
    
    

}
	//forall 	(i in 1..n, j in 1..n) totalArdido[i][j] == sum (x in 1..n, y in 1..n) ardido[x][y][i][j]; // total ardido quando a igni��o acontece em (i,j) V�LIDO
	//int totalArdido[1..n][1..n]; //quantas c�lulas arderam (somat�rio das igni��es das c�lulas (x,y)) quando houve igni��o em (i,j)
	
	//n�o deviam de ser necess�rias
    //forall  (i in 1..n, j in 1..n, x in 1..n, y in 1..n) 	1-ardido[i][j][x][y] 	>= 0;
    //forall  (i in 1..n, j in 1..n, x in 1..n, y in 1..n) 	ardido[i][j][x][y] 	>= 0;
    //sum 	(x in 1..n, y in 1..n) equipas[x][y] <=b; 		//total de equipas dispon�veis n�o superior a b
    
//Backups
/*
    forall  (x in 1..n, y in 1..n, i in 1..n, j in 1..n) 	Tempos[x][y][i][j] >= 0; //todos os tempos s�o n�o negativos V�LIDO
    forall 	(i in 1..n, j in 1..n) sum 	(x in 1..n, y in 1..n) ardido[x][y][i][j] >= 1; 	//tem de haver igni��o
	forall 	(x in 1..n, y in 1..n) equipas[x][y] <= 1; 		//apenas podemos ter uma equipa por c�lula desnecess�rio
	forall 	(x in 1..n, y in 1..n) 1 - equipas[x][y] >= 0; 		//apenas podemos ter uma equipa por c�lula, ou 1 ou 0, in�tilpor ter sido declarado como int+
	
	forall	(i in 2..n, j in 1..n)	probIgni[i][j]*(vS[i][j] + Delta*equipas[i][j]) >= Tempos[i-1][j];
	forall	(i in 1..n-1, j in 1..n)	probIgni[i][j]*(vN[i][j] + Delta*equipas[i][j]) >= Tempos[i+1][j];
	forall	(i in 1..n, j in 2..n)	probIgni[i][j]*(vE[i][j] + Delta*equipas[i][j]) >= Tempos[i][j-1];
	forall	(i in 1..n, j in 1..n-1)	probIgni[i][j]*(vW[i][j] + Delta*equipas[i][j]) >= Tempos[i][j+1];

    forall  (i in 1..n, j in 1..n) 	Tempos[i][j][i][j] >= 0; // desnecess�rio, estamos a maximizar o Tempos
    forall  (x in 1..n, y in 1..n, i in 1..n, j in 1..n) 	ardido[x][y][i][j] 	<= 1; 
    total == sum (i in 1..n, j in 1..n) probIgni[i][j]; //a probabilidade global n�o precisa de ser 1, porque na realidade n�o � garantido que haja um inc�ndio no mapa
    maximize sum (i in 1..n, j in 1..n) Tempos[i][j]; //maximizando o tempo vamos passar pelos caminhos mais demorados, dando menos �rea ardida
    
 */  
/*
subject to{ 
	sum 	(i in 1..n, j in 1..n) equipas[i][j] <= b; 		//total de equipas dispon�veis
	sum 	(i in 1..n, j in 1..n) ardido[i][j] >= 1; 		//tem de haver igni��o
	forall 	(i in 1..n, j in 1..n) equipas[i][j] <= 1; 		//apenas podemos ter uma equipa por c�lula
	forall 	(i in 2..n, j in 1..n) 		Tempos[i-1][j] - Tempos[i][j] <= vN[i][j] + Delta*equipas[i][j]; //tempo de propaga��o para a c�lula adjacente a Norte
    forall	(i in 1..n-1, j in 1..n)	Tempos[i+1][j] - Tempos[i][j] <= vS[i][j] + Delta*equipas[i][j]; //tempo de propaga��o para a c�lula adjacente a Sul
    forall 	(i in 1..n, j in 2..n) 		Tempos[i][j-1] - Tempos[i][j] <= vW[i][j] + Delta*equipas[i][j]; //tempo de propaga��o para a c�lula adjacente a Oeste
    forall 	(i in 1..n, j in 1..n-1)	Tempos[i][j+1] - Tempos[i][j] <= vE[i][j] + Delta*equipas[i][j]; //tempo de propaga��o para a c�lula adjacente a Este
    forall 	(i in 1..n, j in 1..n) 		ardido[i][j] == (Tempos[i][j]<=time); // se chegou l� at� aos 12 segundos, ardeu
    //total == sum (i in 1..n, j in 1..n) probIgni[i][j]; //a probabilidade global n�o precisa de ser 1, porque na realidade n�o � garantido que haja um inc�ndio no mapa
}
*/