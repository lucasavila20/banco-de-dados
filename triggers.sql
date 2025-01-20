CREATE OR REPLACE FUNCTION verifica_consistencia_pedigree()  
RETURNS TRIGGER AS $$  
DECLARE  
    nascimento_pai INTEGER;  
    nascimento_mae INTEGER;  
    idade_pai INTEGER; 
    idade_mae INTEGER; 
BEGIN  
    IF NEW.pai IS NOT NULL THEN  
        SELECT nascimento INTO nascimento_pai FROM pedigree WHERE animal = NEW.pai;  

        IF nascimento_pai IS NULL THEN  
            INSERT INTO pai_inexistente (animal, pai, mae, internacional, nascimento, origem)  
            VALUES (NEW.animal, NEW.pai, NEW.mae, NEW.internacional, NEW.nascimento, NEW.origem);  
            RETURN NULL;  
        END IF;  
        
        idade_pai := NEW.nascimento - nascimento_pai;  
        
        IF idade_pai < 2 THEN 
            INSERT INTO pai_novo (animal, pai, mae, internacional, nascimento, origem) 
            VALUES (NEW.animal, NEW.pai, NEW.mae, NEW.internacional, NEW.nascimento, NEW.origem); 
            RETURN NULL; 
        END IF; 
    END IF; 

    IF NEW.mae IS NOT NULL THEN 
        SELECT nascimento INTO nascimento_mae FROM pedigree WHERE animal = NEW.mae; 
        
        IF nascimento_mae IS NULL THEN 
            INSERT INTO mae_inexistente (animal, pai, mae, internacional, nascimento, origem) 
            VALUES (NEW.animal, NEW.pai, NEW.mae, NEW.internacional, NEW.nascimento, NEW.origem); 
            RETURN NULL; 
        END IF; 
        
        idade_mae := NEW.nascimento - nascimento_mae; 
        
        IF idade_mae < 2 THEN 
            INSERT INTO mae_nova (animal, pai, mae, internacional, nascimento, origem) 
            VALUES (NEW.animal, NEW.pai, NEW.mae, NEW.internacional, NEW.nascimento, NEW.origem); 
            RETURN NULL; 
        END IF; 
    END IF; 

    IF NEW.nascimento <= 1910 THEN
         RETURN NULL;
    END IF;
    
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;











CREATE OR REPLACE FUNCTION verificar_limite_de_filhos()
RETURNS TRIGGER AS $$
DECLARE
    total_filhos INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO total_filhos
    FROM pedigree
    WHERE mae = NEW.mae;
    
    IF total_filhos >= 20 THEN
        RAISE EXCEPTION 'Uma vaca não pode ser mãe de mais de 20 animais.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_limite_de_filhos 
BEFORE INSERT OR UPDATE ON pedigree 
FOR EACH ROW 
EXECUTE FUNCTION verificar_limite_de_filhos(); 


















CREATE OR REPLACE FUNCTION genotipada_br()
RETURNS TRIGGER AS $$
DECLARE
    sexo_animal char(1);
    origem_animal char(3);
BEGIN
    SELECT sexo, origem
    INTO sexo_animal, origem_animal
    FROM pedigree
    WHERE internacional = NEW.internacional;
    
    IF sexo_animal = 'F' THEN
      IF origem_animal <> 'BRA' THEN
          RAISE EXCEPTION 'Uma vaca genotipada não pode ser estrangeira';
      END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_genotipada_br 
BEFORE INSERT OR UPDATE ON genotipagem 
FOR EACH ROW 
EXECUTE FUNCTION genotipada_br(); 
















CREATE OR REPLACE FUNCTION producao_br()
RETURNS TRIGGER AS $$
DECLARE
    sexo_animal char(1);
    origem_animal char(3);
BEGIN
    SELECT sexo, origem
    INTO sexo_animal, origem_animal
    FROM pedigree
    WHERE animal = NEW.animal;
    
    IF sexo_animal = 'F' THEN
      IF origem_animal <> 'BRA' THEN
          RAISE EXCEPTION 'Não se pode registrar produção de vacas estrangeiras';
      END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_producao_br 
BEFORE INSERT OR UPDATE ON producao 
FOR EACH ROW 
EXECUTE FUNCTION producao_br(); 
