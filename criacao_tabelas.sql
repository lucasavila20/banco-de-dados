CREATE TABLE pedigree(
    animal VARCHAR(20) NOT NULL UNIQUE,
    pai VARCHAR(20),
    mae VARCHAR(20),
    internacional VARCHAR(19) NOT NULL UNIQUE,
    nascimento INTEGER,
    origem INTEGER,
    PRIMARY KEY (internacional)
);

ALTER TABLE pedigree
    ADD CONSTRAINT animal_format_check
    CHECK (animal ~ '^[A-Za-z]{2}[0-9]+$');

ALTER TABLE pedigree
    ADD COLUMN setimo_digito CHAR(1) 
    GENERATED ALWAYS AS (SUBSTRING(internacional FROM 7 FOR 1)) STORED;

ALTER TABLE pedigree 
RENAME COLUMN setimo_digito TO sexo;

CREATE TABLE alias(
    internacional VARCHAR(19) NOT NULL REFERENCES pedigree(internacional),
    internacional2 VARCHAR(19) NOT NULL,
    PRIMARY KEY (internacional, internacional2)
);

CREATE TABLE producao(
    animal VARCHAR(20) NOT NULL REFERENCES pedigree(animal),
    lactacao INTEGER NOT NULL,
    controle INTEGER NOT NULL,
    peso FLOAT,
    proteina FLOAT,
    gordura FLOAT,
    acs FLOAT,
    PRIMARY KEY (animal, lactacao, controle)
);

ALTER TABLE producao
    ADD CONSTRAINT lactacao_check 
    CHECK (lactacao IN (1, 2, 3));

ALTER TABLE producao
    ADD CONSTRAINT controle_check 
    CHECK (controle IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10));

CREATE TABLE produtor(
    nome VARCHAR(50) NOT NULL,
    id_produtor INTEGER NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    clima VARCHAR(20) NOT NULL,
    forma_extracao INTEGER NOT NULL,
    PRIMARY KEY (id_produtor)
);

ALTER TABLE produtor DROP COLUMN forma_extracao;
ALTER TABLE produtor DROP COLUMN clima;

CREATE TABLE rebanho(
    animal VARCHAR(20) NOT NULL UNIQUE REFERENCES pedigree(animal),
    rebanho INTEGER NOT NULL,
    id_produtor INTEGER NOT NULL REFERENCES produtor(id_produtor),
    clima VARCHAR(20) NOT NULL,
    forma_extracao VARCHAR(20) NOT NULL,
    PRIMARY KEY (animal)
);

CREATE TABLE empresa_genotipagem(
    nome VARCHAR(50) NOT NULL,
    cnpj VARCHAR(18) NOT NULL,
    telefone VARCHAR(20),
    pais VARCHAR(30),
    PRIMARY KEY (cnpj)
);

CREATE TABLE pedido(
    internacional VARCHAR(19) NOT NULL REFERENCES pedigree(internacional),
    OS INTEGER NOT NULL,
    cnpj VARCHAR(18) NOT NULL REFERENCES empresa_genotipagem(cnpj),
    id_produtor INTEGER NOT NULL REFERENCES produtor(id_produtor),
    PRIMARY KEY (internacional, OS)
);


CREATE TABLE genotipagem(
    internacional VARCHAR(19) NOT NULL,
    OS INTEGER NOT NULL,
    genotipo VARCHAR(10000) NOT NULL,
    PRIMARY KEY (internacional),
    FOREIGN KEY (internacional, OS) REFERENCES pedido(internacional, OS) 
);


CREATE TABLE caracteristica_lactacao(
    animal VARCHAR(20) NOT NULL,
    lactacao INTEGER NOT NULL,
    controle INTEGER NOT NULL,
    status INTEGER NOT NULL CHECK (status IN (1, 2, 3)),
    causa VARCHAR(1500),
    previsao_volta date,
    PRIMARY KEY (animal, lactacao, controle),
    FOREIGN KEY (animal, lactacao, controle) REFERENCES producao(animal, lactacao, controle)
);


CREATE TABLE producao_andamento ( 
    animal VARCHAR(20),
    lactacao INTEGER,
    controle INTEGER,
    PRIMARY KEY (animal, lactacao, controle),
    FOREIGN KEY (animal, lactacao, controle) REFERENCES caracteristica_lactacao(animal, lactacao, controle)
);


create table producao_interrompida ( 
animal varchar(15),
lactacao INTEGER,
controle INTEGER,
status INTEGER,
causa varchar(1500),
previsao_volta date,
PRIMARY KEY (animal, lactacao, controle),
FOREIGN KEY (animal, lactacao, controle) REFERENCES caracteristica_lactacao(animal, lactacao, controle)
);

create table producao_finalizada( 
animal varchar(15),
lactacao INTEGER,
controle INTEGER,
status INTEGER,
causa varchar(1500),
PRIMARY KEY (animal, lactacao, controle),
FOREIGN KEY (animal, lactacao, controle) REFERENCES caracteristica_lactacao(animal, lactacao, controle)
);

CREATE OR REPLACE FUNCTION insere_prod_andamento() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO producao_andamento (animal, lactacao, controle) 
    VALUES (NEW.animal, NEW.lactacao, NEW.controle);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER andamento
AFTER INSERT OR UPDATE ON caracteristica_lactacao
FOR EACH ROW
WHEN (NEW.status = 1) 
EXECUTE FUNCTION insere_prod_andamento();



CREATE OR REPLACE FUNCTION insere_prod_interrompida() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO producao_interrompida (animal, lactacao, controle, causa, previsao_volta) 
    VALUES (NEW.animal, NEW.lactacao, NEW.controle, NEW.causa, NEW.previsao_volta);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION atualiza_prod_interrompida() 
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producao_interrompida
    SET causa = NEW.causa, previsao_volta =  NEW.previsao_volta
    WHERE animal = NEW.animal AND lactacao = NEW.lactacao AND controle = NEW.controle;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER interrompida 
AFTER INSERT ON caracteristica_lactacao 
FOR EACH ROW 
WHEN (NEW.status = 2)  
EXECUTE FUNCTION insere_prod_interrompida();


CREATE OR REPLACE TRIGGER interrompida_att 
AFTER UPDATE ON caracteristica_lactacao 
FOR EACH ROW 
WHEN (NEW.status = 2)  
EXECUTE FUNCTION atualiza_prod_interrompida();


CREATE OR REPLACE FUNCTION insere_prod_finalizada() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO producao_finalizada (animal, lactacao, controle, causa) 
    VALUES (NEW.animal, NEW.lactacao, NEW.controle, NEW.causa);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION atualiza_prod_finalizada() 
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producao_finalizada 
    SET causa = NEW.causa
    WHERE animal = NEW.animal AND lactacao = NEW.lactacao AND controle = NEW.controle;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER finalizada  
AFTER INSERT ON caracteristica_lactacao 
FOR EACH ROW 
WHEN (NEW.status = 3)  
EXECUTE FUNCTION insere_prod_finalizada();

CREATE OR REPLACE TRIGGER finalizada_att  
AFTER UPDATE ON caracteristica_lactacao 
FOR EACH ROW 
WHEN (NEW.status = 3)  
EXECUTE FUNCTION atualiza_prod_finalizada();

CREATE TABLE compra_animal (
    id SERIAL PRIMARY KEY,
    animal VARCHAR(20) NOT NULL,
    comprador INTEGER NOT NULL REFERENCES produtor(id_produtor),
    vendedor INTEGER NOT NULL REFERENCES produtor(id_produtor),
    valor FLOAT
);

CREATE TABLE compradores_leite (
    id_cliente VARCHAR(20) NOT NULL,
    nome VARCHAR(50) NOT NULL,
    telefone VARCHAR(20),
    PRIMARY KEY (id_cliente)
);

CREATE TABLE compra_leite (
    id_cliente VARCHAR(20) NOT NULL REFERENCES compradores_leite(id_cliente),
    id_produtor INTEGER NOT NULL REFERENCES produtor(id_produtor),
    quantidade VARCHAR(20) NOT NULL,
    data_compra_leite DATE NOT NULL,
    preco_kg FLOAT,
    PRIMARY KEY (id_cliente, id_produtor, data_compra_leite)
);

CREATE TABLE fornecedor_alimento (
    id_fornecedor VARCHAR(20) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_fornecedor)
);

CREATE TABLE compra_alimento (
    id_fornecedor VARCHAR(20) NOT NULL REFERENCES fornecedor_alimento(id_fornecedor),
    id_produtor INTEGER NOT NULL REFERENCES produtor(id_produtor),
    alimento INTEGER NOT NULL,
    PRIMARY KEY (id_fornecedor, id_produtor)
);

ALTER TABLE compra_alimento 
ALTER COLUMN alimento TYPE varchar(150);

CREATE TABLE mapa (
    internacional CHAR(19) NOT NULL REFERENCES genotipagem(internacional),
    alelo INTEGER NOT NULL,
    posicao INTEGER NOT NULL,
    marcador VARCHAR(50) NOT NULL,
    PRIMARY KEY (internacional, alelo, posicao, marcador)
);

SELECT constraint_name 
FROM information_schema.table_constraints 
WHERE table_name = 'mapa' 
  AND constraint_type = 'PRIMARY KEY';
  
ALTER TABLE mapa  
DROP CONSTRAINT mapa_pkey;

ALTER TABLE mapa 
ADD CONSTRAINT mapa_pkey 
PRIMARY KEY (internacional, alelo, posicao);



CREATE TABLE pai_inexistente (
    animal VARCHAR(20) NOT NULL UNIQUE,
    pai VARCHAR(20),
    mae VARCHAR(20),
    internacional VARCHAR(19) NOT NULL UNIQUE,
    nascimento INTEGER,
    origem CHAR(3), 
    PRIMARY KEY (internacional)
);

CREATE TABLE pai_novo (
    animal VARCHAR(20) NOT NULL UNIQUE,
    pai VARCHAR(20),
    mae VARCHAR(20),
    internacional VARCHAR(19) NOT NULL UNIQUE,
    nascimento INTEGER,
    origem CHAR(3), 
    PRIMARY KEY (internacional)
);


-- Tabela para armazenar registros com inconsistências na mãe
CREATE TABLE mae_inexistente (
    animal VARCHAR(20) NOT NULL UNIQUE,
    pai VARCHAR(20),
    mae VARCHAR(20),
    internacional VARCHAR(19) NOT NULL UNIQUE,
    nascimento INTEGER,
    origem CHAR(3), 
    PRIMARY KEY (internacional)
);

CREATE TABLE mae_nova (
    animal VARCHAR(20) NOT NULL UNIQUE,
    pai VARCHAR(20),
    mae VARCHAR(20),
    internacional VARCHAR(19) NOT NULL UNIQUE,
    nascimento INTEGER,
    origem CHAR(3), 
    PRIMARY KEY (internacional)
);