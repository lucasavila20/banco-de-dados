-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

-- 1) Informações dos animais genotipados
SELECT * 
FROM pedigree
WHERE internacional IN (SELECT internacional FROM genotipagem);

-- visao 1)
-- 2) Produção média de leite dos animais genotipados
SELECT animal, AVG(peso), AVG(proteina), AVG(gordura), AVG(acs)   
FROM producao 
WHERE animal IN 
(SELECT animal 
FROM pedigree 
WHERE internacional IN (SELECT internacional FROM genotipagem))
GROUP BY animal;


-- 3) Produção média de leite dos animais de acordo com a alimentação
SELECT AVG(peso), alimento   
FROM pedigree 
INNER JOIN producao 
ON pedigree.animal = producao.animal 
LEFT JOIN 
rebanho 
ON rebanho.rebanho = pedigree.rebanho 
LEFT JOIN 
compra_alimento 
ON rebanho.id_produtor = compra_alimento.id_produtor 
GROUP BY alimento;

-- 4) Causas mais comuns de interrupção da produção
SELECT causa, COUNT(causa) 
FROM producao_interrompida  
GROUP BY causa;


-- 5) Pedidos que não resultaram em genotipagem, com informações do produtor
SELECT internacional, os, pedido.id_produtor, nome, telefone  
FROM pedido    
LEFT JOIN  
produtor  
ON pedido.id_produtor = produtor.id_produtor 
WHERE internacional NOT IN  
(SELECT internacional FROM genotipagem);


-- 5) Pedidos que não resultaram em genotipagem, com informações do produtor
SELECT internacional, os, pedido.id_produtor, nome, telefone  
FROM pedido    
LEFT JOIN  
produtor  
ON pedido.id_produtor = produtor.id_produtor 
WHERE internacional NOT IN  
(SELECT internacional FROM genotipagem);


-- 6) Prodção total de cada vaca em cada lactação
SELECT animal, lactacao, SUM(peso) as total_leite, SUM(gordura) as total_gordura, 
SUM(proteina) as total_proteina, SUM(acs) as total_acs 
FROM producao 
GROUP BY animal, lactacao;


-- 7) Qual o controle em que a média de leite produzida foi a maior para cada lactação

SELECT * 
FROM 
(SELECT lactacao, MAX(media_peso) as maximo_peso 
FROM( 
SELECT controle, lactacao, AVG(peso) as media_peso 
FROM producao 
GROUP BY controle, lactacao) 
GROUP BY lactacao) tab1 
LEFT JOIN 
(SELECT controle, lactacao, AVG(peso) as media_peso 
FROM producao 
GROUP BY controle, lactacao) tab2 
ON tab1.lactacao = tab2.lactacao AND tab1.maximo_peso = tab2.media_peso;

-- 8) Quantidade de animais pertencidos a cada produtor, 
-- mostrando caso não tenha responsável também
SELECT rebanho.id_produtor, COUNT(animal)  
FROM pedigree  
LEFT JOIN rebanho 
ON pedigree.rebanho = rebanho.rebanho 
LEFT JOIN 
produtor 
ON produtor.id_produtor = rebanho.id_produtor 
GROUP BY rebanho.id_produtor;

-- 9) Quantidade de animais pertencidos a cada produtor, 
-- com as informações deles 
SELECT p.*, quantidade_animais 
FROM produtor p 
LEFT JOIN 
(SELECT rebanho.id_produtor, COUNT(animal) as quantidade_animais   
FROM pedigree  
LEFT JOIN rebanho 
ON pedigree.rebanho = rebanho.rebanho 
LEFT JOIN 
produtor 
ON produtor.id_produtor = rebanho.id_produtor 
GROUP BY rebanho.id_produtor) t1 
ON t1.id_produtor = p.id_produtor;

-- 10) Preço médio do quilo vendido por cada produtor em cada ano

SELECT id_produtor, AVG(preco_kg) preco_medio, EXTRACT(YEAR FROM data_compra_leite) ano_compra    
FROM compra_leite 
GROUP BY id_produtor, EXTRACT(YEAR FROM data_compra_leite);

-- 11) status atual (ou último) de produção de cada vaca

SELECT animal, MAX(lactacao) as ultima_lactacao 
FROM producao 
GROUP BY 
animal; 


-- 12 ) producao feita no ultimo controle, e, 
-- se ela estiver interrompida ou finalizada, o motivo
SELECT *
FROM 
producao p 
LEFT JOIN 
(SELECT animal, MAX(lactacao) as ultima_lactacao 
FROM producao 
GROUP BY 
animal) t 
ON p.animal = t.animal AND p.lactacao = t.ultima_lactacao;




SELECT t.animal, MAX(controle) as ultimo_controle, ultima_lactacao  
FROM 
producao p 
LEFT JOIN 
(SELECT animal, MAX(lactacao) as ultima_lactacao 
FROM producao 
GROUP BY 
animal) t 
ON p.animal = t.animal AND p.lactacao = t.ultima_lactacao 
GROUP BY t.animal;




SELECT b.animal, MAX(controle) as ultimo_controle, b.ultima_lactacao 
FROM 
(SELECT *  
FROM 
producao p 
LEFT JOIN 
(SELECT animal as a, MAX(lactacao) as ultima_lactacao 
FROM producao 
GROUP BY 
animal) t 
ON p.animal = t.a AND p.lactacao = t.ultima_lactacao ) b 
GROUP BY b.animal, b.ultima_lactacao;


SELECT * 
FROM 
(SELECT b.animal, MAX(controle) as ultimo_controle, b.ultima_lactacao 
FROM 
(SELECT *  
FROM 
producao p 
LEFT JOIN 
(SELECT animal as a, MAX(lactacao) as ultima_lactacao 
FROM producao 
GROUP BY 
animal) t 
ON p.animal = t.a AND p.lactacao = t.ultima_lactacao ) b 
GROUP BY b.animal, b.ultima_lactacao) c 
LEFT JOIN 
caracteristica_lactacao 
ON ultimo_controle = controle AND ultima_lactacao = lactacao AND 
c.animal = caracteristica_lactacao.animal AND status <> 1;

-- visao 2
-- 13) Informações de pedigree completas

SELECT animal, pai, mae, internacional, pinter, minter, nascimento, pnasc, mnasc, 
origem, porig, morig    
FROM (pedigree p1 
LEFT JOIN 
(SELECT p2.animal as ani, 
        p2.internacional as pinter, 
        p2.nascimento as pnasc, 
        p2.origem as porig 
  FROM pedigree p2) p3 
ON p3.ani = p1.pai ) 
LEFT JOIN 
(SELECT p4.animal as mani, 
        p4.internacional as minter, 
        p4.nascimento as mnasc, 
        p4.origem as morig 
  FROM pedigree p4) p5  
ON p5.mani = p1.mae; 


-- 14) Animais genotipados que não tenham pai ou mãe 


SELECT animal, pai, mae, internacional, pinter, minter, nascimento, pnasc, mnasc, 
origem, porig, morig    
FROM (pedigree p1 
LEFT JOIN 
(SELECT p2.animal as ani, 
        p2.internacional as pinter, 
        p2.nascimento as pnasc, 
        p2.origem as porig 
  FROM pedigree p2) p3 
ON p3.ani = p1.pai ) 
LEFT JOIN 
(SELECT p4.animal as mani, 
        p4.internacional as minter, 
        p4.nascimento as mnasc, 
        p4.origem as morig 
  FROM pedigree p4) p5  
ON p5.mani = p1.mae 
WHERE internacional IN 
(SELECT internacional FROM genotipagem) AND 
(mae IS NULL OR pai IS NULL);


-- 15) De quantos animais, pais e mães diferentes é composto o pedigree 

SELECT COUNT(DISTINCT(animal)) as qntidade_animal, COUNT(DISTINCT(pai)) as qntidade_pai,
COUNT(DISTINCT(mae)) as qntidade_mae 
FROM pedigree;


