PROMPT CREATE FUNCTION "READ_MID_MER"
CREATE OR REPLACE FUNCTION READ_MID_MER
/*поиск мероприятия по названию и коду*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
		RETURN NUMBER IS
			cursor_mer_id cp_mer.m_id%TYPE;
BEGIN
	SELECT m_id
		INTO cursor_mer_id
	FROM cp_mer
	WHERE	mer_name = param_mer_name AND
			mer_code = param_mer_code;
	RETURN cursor_mer_id;
	EXCEPTION
		WHEN no_data_found THEN
			RETURN -2000;/*заглушка*/
END READ_MID_MER;
/
PROMPT CREATE FUNCTION "READ_PARENT_MER"
CREATE OR REPLACE FUNCTION READ_PARENT_MER
/*поиск мероприятия-родителя*/
	(param_mer_name	IN	cp_mer.mer_name%TYPE,
	param_mer_code	IN	cp_mer.mer_code%TYPE)
	RETURN NUMBER IS
		cursor_mer_id cp_mer.m_id%TYPE;
		n NUMBER;
BEGIN
	SELECT E.M_ID
		INTO n
	FROM CP_MER E, CP_MER F
	WHERE E.MER_NODE = F.MER_PARENT AND
		F.M_ID = READ_MID_MER(param_mer_name, param_mer_code);
	RETURN n;
	EXCEPTION
		WHEN no_data_found THEN
			RETURN -1000;/*заглушка*/
END READ_PARENT_MER;
/
PROMPT CREATE FUNCTION "READ_COUNT_MER"
CREATE OR REPLACE FUNCTION READ_COUNT_MER
/*наличие мероприятия*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
	RETURN NUMBER IS
		n NUMBER;
BEGIN
	SELECT COUNT(*)
		INTO n
	FROM dual
	WHERE EXISTS
		(SELECT null FROM cp_mer
		WHERE m_id = READ_MID_MER(param_mer_name, param_mer_code));
RETURN n;
END READ_COUNT_MER;
/
PROMPT CREATE FUNCTION "READ_END_MER"
CREATE OR REPLACE FUNCTION READ_END_MER
/*проверка мероприятия на наличие потомков*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
		RETURN NUMBER IS
			cursor_end_mer number;
BEGIN
	SELECT COUNT(*)
		INTO cursor_end_mer
	FROM cp_mer e
	WHERE m_id = READ_MID_MER(param_mer_name, param_mer_code) AND
		NOT EXISTS
			(SELECT m_id
			FROM cp_mer f
			WHERE e.mer_node=f.mer_parent);
	RETURN cursor_end_mer;
END READ_END_MER;
/
PROMPT CREATE FUNCTION "READ_COUNT_CHILD_MER"
CREATE OR REPLACE FUNCTION READ_COUNT_CHILD_MER
/*количество прямых потомков мероприятия*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE) 
		RETURN NUMBER IS
			cursor_count_child_mer NUMBER;
BEGIN
	SELECT COUNT(*)
		INTO cursor_count_child_mer
	FROM cp_mer
	WHERE mer_parent =
		(SELECT mer_node FROM cp_mer
		WHERE m_id = READ_MID_MER(param_mer_name, param_mer_code));
	RETURN cursor_count_child_mer;
END READ_COUNT_CHILD_MER;
/
PROMPT CREATE FUNCTION "READ_COUNT_USR_MER"
CREATE OR REPLACE FUNCTION READ_COUNT_USR_MER
/*количество участников в мероприятии*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
	RETURN NUMBER IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_count_usr_mer NUMBER;
BEGIN
	SELECT READ_MID_MER(param_mer_name, param_mer_code)
		INTO cursor_mer_id
	FROM dual;
	SELECT COUNT(*)
		INTO cursor_count_usr_mer
	FROM mer_to_usr
	WHERE mer_id = cursor_mer_id;
RETURN cursor_count_usr_mer;
END READ_COUNT_USR_MER;
/
PROMPT CREATE FUNCTION "READ_EXISTS_USR_MER"
CREATE OR REPLACE FUNCTION READ_EXISTS_USR_MER
/*наличие данного участника в мероприятии*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_username IN cp_users.user_name%TYPE)
	RETURN NUMBER IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_user_id cp_users.user_id%TYPE;
		cursor_exists_usr_in_mer NUMBER;
BEGIN
	/*найдем данное мероприятие*/
	SELECT READ_MID_MER(param_mer_name, param_mer_code)
		INTO cursor_mer_id
	FROM dual;
	/*������ ���������*/
	SELECT user_id
		INTO cursor_user_id
	FROM cp_users
	WHERE user_name = param_username;
	/*определим наличие пользователя в мероприятии
	без подсчета всех строк. 1 - да, 0 - нет.*/
	SELECT COUNT(*)
		INTO cursor_exists_usr_in_mer
	FROM dual
	WHERE EXISTS
		(SELECT NULL
		FROM mer_to_usr
		WHERE	mer_id = cursor_mer_id AND
				usr_id = cursor_user_id);
RETURN cursor_exists_usr_in_mer;
END READ_EXISTS_USR_MER;
/
PROMPT FUNCTION "READ_SUM_BROTHERS_MER"
CREATE OR REPLACE FUNCTION READ_SUM_BROTHERS_MER
/*сумма "братьев"*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
		RETURN NUMBER IS
			n cp_mer.fin%TYPE;
BEGIN
	SELECT NVL(SUM(fin),0)
		INTO n
	FROM cp_mer
	WHERE m_id NOT IN
		(SELECT READ_MID_MER(param_mer_name, param_mer_code) FROM dual) AND
		mer_parent =
			(SELECT mer_parent FROM cp_mer
			WHERE m_id=READ_MID_MER(param_mer_name, param_mer_code));
		
	RETURN n;
END READ_SUM_BROTHERS_MER;
/
PROMPT FUNCTION "READ_SUM_CHILD_MER"
CREATE OR REPLACE FUNCTION READ_SUM_CHILD_MER
/*сумма потомков*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
		RETURN NUMBER IS
			cursor_mer_node cp_mer.mer_node%TYPE;
			n cp_mer.fin%TYPE;
BEGIN
	SELECT NVL(SUM(fin),0)
		INTO n
	FROM cp_mer
	WHERE mer_parent =
		(SELECT mer_node FROM cp_mer
		WHERE m_id=READ_MID_MER(param_mer_name, param_mer_code));
	RETURN n;
END READ_SUM_CHILD_MER;
/
PROMPT FUNCTION "READ_SUM_PARENT_MER"
CREATE OR REPLACE FUNCTION READ_SUM_PARENT_MER
/*сумма родителя*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
		RETURN NUMBER IS
			n cp_mer.fin%TYPE;
BEGIN
	SELECT NVL(SUM(fin),0)
		INTO n
	FROM cp_mer WHERE mer_node =
		(SELECT mer_parent FROM cp_mer
		WHERE m_id=READ_MID_MER(param_mer_name, param_mer_code));
	RETURN n;
END READ_SUM_PARENT_MER;
/
PROMPT FUNCTION "AVAILABLE_FINANCE"
create or replace FUNCTION AVAILABLE_FINANCE
/*функция доступной суммы для обновления с учетом сумм родителей*/
/*Для текущего мероприятия делаем обход дерева вверх до мероприятия с типом
финансирования = 1. Как только нашли, идем вниз до тех пор пока 1)разница сумм
родителя и потомков  > 0 2)не дойдем до текущего мероприятия. 
Возвращается id мероприятия, у которого тип финансирования = 1*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE)
	RETURN NUMBER IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_fin cp_mer.fin%TYPE;
		cursor_type_fin cp_mer.type_fin%TYPE;
		cursor_param_mer_code cp_mer.mer_code%TYPE;
		cursor_param_mer_code2 cp_mer.mer_code%TYPE;
BEGIN
	/*данное мероприятие*/
	SELECT READ_MID_MER(param_mer_name, param_mer_code)
		INTO cursor_mer_id
	FROM dual;
	/*тип финансирования данного мероприятия*/
	SELECT type_fin
		INTO cursor_type_fin
	FROM cp_mer
	WHERE m_id = cursor_mer_id;

	IF cursor_type_fin = 0 THEN

		/*переопределим мероприятие*/
		SELECT mer_code
			INTO cursor_param_mer_code
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER( param_mer_name, param_mer_code);

		/*родитель*/
		SELECT READ_MID_MER(  param_mer_name, cursor_param_mer_code)
			INTO cursor_mer_id
		FROM dual;

		/*тип финансирования родителя*/
		SELECT type_fin
			INTO cursor_type_fin
		FROM cp_mer
		WHERE m_id = cursor_mer_id;

		/*найдем ближайшее мероприятие с явным типом финансирования*/
		WHILE cursor_type_fin < 1 LOOP
		SELECT cursor_param_mer_code
			INTO cursor_param_mer_code2
		FROM dual;

		SELECT mer_code
			INTO cursor_param_mer_code
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER(param_mer_name, cursor_param_mer_code2);

		SELECT m_id
			INTO cursor_mer_id
		FROM cp_mer
		WHERE m_id = READ_MID_MER(param_mer_name, cursor_param_mer_code);

		SELECT type_fin
			INTO cursor_type_fin
		FROM cp_mer
		WHERE m_id = cursor_mer_id;
		END LOOP;
	END IF;

	RETURN cursor_mer_id;
END AVAILABLE_FINANCE;
/
PROMPT FUNCTION "CHECK_FINANCE"
create or replace FUNCTION CHECK_FINANCE
/*проверка на сумму мероприятий. Если тип финансирования = 0,
сумма расчитывается по нижележащим элементам, сумма прямого 
потомка может быть любая. Если тип финансирования = 1, то сумма
расчитывается явно, она фиксирована и общая сумма первых потомков
не может ее превышать*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_fin IN cp_mer.fin%TYPE)
		RETURN NUMBER IS
			cursor_mer_id cp_mer.m_id%TYPE;
			cursor_fin cp_mer.fin%TYPE;
			cursor_fin_brothers cp_mer.fin%TYPE;
			cursor_type_fin cp_mer.type_fin%TYPE;
			cursor_param_fin cp_mer.fin%TYPE;
			cursor_param_mer_code cp_mer.mer_code%TYPE;
			cursor_cursor_type_fin cp_mer.type_fin%TYPE;
BEGIN
	/*вначале проверим тип финансирования текущего мероприятия*/
	SELECT type_fin
		INTO cursor_type_fin
	FROM cp_mer
	WHERE m_id = READ_MID_MER(param_mer_name, param_mer_code);
	/*===================проверка на уровне потомка====================*/
	/*если сумма расчитывается явно(фиксирована)*/
	IF cursor_type_fin = 1 THEN
		/*выберем сумму текущего мероприятия*/
		SELECT fin
			INTO cursor_fin
		FROM cp_mer
		WHERE m_id = READ_MID_MER(param_mer_name, param_mer_code);
		/*сравним сумму и вставляемую сумму и выберем меньшую*/
		IF param_fin > cursor_fin THEN
			RETURN cursor_fin;
		ELSE
			RETURN param_fin;
		END IF;
	/*если сумма мероприятия расчитывается по потомкам(не фиксирована)*/
	ELSE
		/*если мероприятие расчитывается по потомкам, то оно не корневое,
		так как у корневого сумма расчитывается явно. Значит у мероприятия
		есть родитель*/
		/*тип финансирования родителя*/
		SELECT type_fin
			INTO cursor_type_fin
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER(param_mer_name, param_mer_code);
		/*сумма родителя*/
		SELECT fin
			INTO cursor_fin
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER(param_mer_name, param_mer_code);
		/*сумма "братьев"*/
		SELECT READ_SUM_BROTHERS_MER(param_mer_name, param_mer_code)
			INTO cursor_fin_brothers
		FROM dual;
		/*===================проверка на уровне родителя====================*/
		/*если сумма расчитывается явно(фиксирована)*/
		IF cursor_type_fin = 1 THEN
			/*сравним сумму, состоящую из разницы суммы родителя и братьев, и
			вставляемую сумму и выберем меньшую*/
			IF param_fin > cursor_fin - cursor_fin_brothers THEN
				/*сумма "братьев" всегда меньше суммы родителя(проверка и обновление
				происходит в UPD_MER)*/
				RETURN cursor_fin - cursor_fin_brothers;
			ELSE
				RETURN param_fin;
			END IF;
			/*если сумма расчитывается по потомкам*/
		ELSE
			/*максимальная доступная сумма*/
			SELECT fin
				INTO cursor_fin
			FROM cp_mer
			WHERE m_id = AVAILABLE_FINANCE(param_mer_name, param_mer_code);
			IF param_fin < cursor_fin THEN
				RETURN param_fin;
			END IF;
		END IF;
	END IF;
END CHECK_FINANCE;
/
PROMPT FUNCTION "CHECK_DATE_START_FOR_CHILD"
CREATE OR REPLACE FUNCTION CHECK_DATE_START_FOR_CHILD
/*проверка даты начала*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_year_start IN cp_mer.year_start%TYPE)
		RETURN NUMBER IS
			cursor_year_start cp_mer.year_start%TYPE;
			cursor_year_stop cp_mer.year_stop%TYPE;
BEGIN
	IF READ_PARENT_MER(param_mer_name, param_mer_code) = 1 THEN
		SELECT year_start, year_stop
			INTO cursor_year_start, cursor_year_stop
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER(param_mer_name, param_mer_code);
	END IF;
	IF param_year_start BETWEEN cursor_year_stop AND cursor_year_start THEN
		RETURN param_year_start;
	ELSE
		RETURN cursor_year_start;
	END IF;
END CHECK_DATE_START_FOR_CHILD;
/
PROMPT FUNCTION "CHECK_DATE_STOP_FOR_CHILD"
CREATE OR REPLACE FUNCTION CHECK_DATE_STOP_FOR_CHILD
/*проверка даты конца*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_year_stop IN cp_mer.year_stop%TYPE)
		RETURN NUMBER IS
			cursor_year_start cp_mer.year_start%TYPE;
			cursor_year_stop cp_mer.year_stop%TYPE;
BEGIN
	IF READ_PARENT_MER(param_mer_name, param_mer_code) > 0 THEN
		SELECT year_start, year_stop
			INTO cursor_year_start, cursor_year_stop
		FROM cp_mer
		WHERE m_id = READ_PARENT_MER(param_mer_name, param_mer_code);
	END IF;
	IF param_year_stop BETWEEN cursor_year_stop AND cursor_year_start THEN
		RETURN param_year_stop;
	ELSE
		RETURN cursor_year_stop;
	END IF;
END CHECK_DATE_STOP_FOR_CHILD;
/