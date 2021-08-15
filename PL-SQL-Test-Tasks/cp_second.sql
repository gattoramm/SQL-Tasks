PROMPT CREATE FUNCTION "ADD_MER"
CREATE OR REPLACE PROCEDURE ADD_MER
/*добавление мероприятия*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_parent_mer_name IN cp_mer.mer_name%TYPE,
	param_parent_mer_code IN cp_mer.mer_code%TYPE,
	param_cp IN cp_mer.cp%TYPE,
	param_year_start IN cp_mer.year_start%TYPE,
	param_year_stop IN cp_mer.year_stop%TYPE,
	param_fin IN cp_mer.fin%TYPE,
	param_type_fin IN cp_mer.type_fin%TYPE) IS
		cursor_count_usr_in_mer NUMBER;
BEGIN
	/*если нет добавляемого мероприятия в базе*/
	IF READ_COUNT_MER(param_mer_name, param_mer_code) = 0 THEN
		/*если есть мероприятие-родитель*/
		IF READ_COUNT_MER(param_parent_mer_name, param_parent_mer_code) = 1 THEN
			INSERT INTO cp_mer
				(m_id,
				mer_name,
				mer_code,
				mer_parent,
				mer_node,
				cp,
				year_start,
				year_stop,
				fin,
				type_fin)
			VALUES
				(cp_mer_seq.nextval,
				param_mer_name,
				param_mer_code,
				(SELECT mer_node FROM cp_mer
				WHERE m_id = READ_MID_MER(	param_parent_mer_name,
											param_parent_mer_code)),
				parent_mer_seq.nextval,
				param_cp,
				CHECK_DATE_START_FOR_CHILD(	param_parent_mer_name,
											param_parent_mer_code,
											param_year_start),
				CHECK_DATE_STOP_FOR_CHILD(	param_parent_mer_name,
											param_parent_mer_code,
											param_year_stop),
				CHECK_FINANCE(	param_parent_mer_name,
											param_parent_mer_code,
											param_fin),
				param_type_fin);
				/*Мероприятие не может состоять из одного потомка. В этом
				случае потомок переходит в родительское. (LEVEL становится
				на 1 меньше)
				При добавлении участника "К" в мероприятие-потомок "Р"(в мероприятие-
				родитель нельзя) с участником "Л", у мероприятия "Р" появляются 2 потомка
				 мероприятие "Р1" с участником "Л" и мероприятие "Р2" с участником
				 "К". Тип финансирования мероприятий "Р1", "Р2" такой же, как в "Р".

				Обновим сумму родителя. Если сумма родителя меньше, чем сумма
				потомков после добавления и тип 
				потомок. аналогично, делаем таким же образом поднимаемся
				на уровень выше до тех пор пока тип финансирования родителя = 0
				и сумма родителя больше суммы предка*/

				/*здесь необходимо добавить обновление таблицы mer_to_usr.
				Если добавляем мероприятие-потомок, то пользователь из 
				мероприятия-родителя, если он есть, переходит в мероприятие-потомок*/
				/*количество участников в данном мероприятии*/
				SELECT COUNT(*)
					INTO cursor_count_usr_in_mer
				FROM mer_to_usr
				WHERE	usr_id IS NOT NULL AND
						mer_id = READ_MID_MER(param_parent_mer_name, param_parent_mer_code);

				/*если есть участники в родительском мероприятии - перенесем их*/
				IF cursor_count_usr_in_mer > 0 THEN
					UPDATE mer_to_usr
					SET mer_id = READ_MID_MER(param_mer_name, param_mer_code)
					WHERE mer_id = READ_MID_MER(param_parent_mer_name, param_parent_mer_code);
				END IF;

		ELSE
			INSERT INTO cp_mer
				(m_id,
				mer_name,
				mer_code,
				mer_parent,
				mer_node,
				cp,
				year_start,
				year_stop,
				fin,
				type_fin)
			VALUES
				(cp_mer_seq.nextval,
				param_mer_name,
				param_mer_code,
				NULL,
				parent_mer_seq.nextval,
				param_cp, param_year_start,
				param_year_stop,
				param_fin, param_type_fin);
		END IF;
	END IF;
END ADD_MER;
/
PROMPT CREATE FUNCTION "DEL_MER"
create or replace PROCEDURE DEL_MER
	/*удаление мероприятия*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE) IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_mer_id_parent cp_mer.m_id%TYPE;
		cursor_mer_id_brother cp_mer.m_id%TYPE;
		cursor_mer_code cp_mer.mer_code%TYPE;
		cursor_mer_code2 cp_mer.mer_code%TYPE;
		cursor_count_brothers NUMBER;
		cursor_exist_child_mer NUMBER;
		cursor_level NUMBER;
		n NUMBER;
BEGIN
	/*если есть данное мероприятие*/
	IF READ_COUNT_MER(param_mer_name, param_mer_code) = 1 THEN

		/*выделим мероприятие, с которого надо начинать удаление*/
		SELECT READ_MID_MER(param_mer_name, param_mer_code)
			INTO cursor_mer_id
		FROM dual;

		/*родитель*/
		SELECT READ_PARENT_MER(param_mer_name, param_mer_code)
			INTO cursor_mer_id_parent
		FROM dual;

		/*удалим данное мероприятие и его потомков*/
		DELETE FROM cp_mer
		WHERE m_id IN
		(SELECT m_id FROM cp_mer
		START WITH m_id = cursor_mer_id
		CONNECT BY mer_parent = PRIOR mer_node);

		/*нужно пересторить дерево, здесь возможны несколько вариантов введем
		несколько обозначений МР - мероприятие-родитель, МП - мероприятие-потомок,
		МУ - мероприятие-узел, МБ - мероприятие-брат*/
		/*если у удаляемого мероприятия > 2 МБ, то, после удаления,
		переименовывается код этих мероприятий.
		если у удаляемого мероприятия 1 МБ, здесь возможны 2 случая
		1) у МБ есть потомки. Перенумеровываются мероприятия. Все поддерево, начиная
		с МБ поднимается на 1 уровень выше(соответств-но переносятся и участники).
		2) у МБ нет потомков. Удаляется также оставшийся МБ и участники этого МБ
		переходят в МР.
		Также нужно пересчитать суммы*/

		/*если есть родитель*/
		IF cursor_mer_id_parent > 0 THEN
		/*==================================================================*/
			/*код родителя*/
			SELECT mer_code
				INTO cursor_mer_code
			FROM cp_mer
			WHERE m_id = cursor_mer_id_parent;

			/*количество "братьев"*/
			SELECT COUNT(*)
				INTO cursor_count_brothers
			FROM cp_mer
			WHERE mer_parent =
				(SELECT mer_node
				FROM cp_mer
				WHERE m_id = cursor_mer_id_parent);

			/*если "братьев" > 1*/
			IF cursor_count_brothers > 1 THEN
    
				/*перенумеруем код мероприятия братьев*/
				n := 1;
				cursor_mer_code2 := cursor_mer_code;

				/*"братья" потомка*/
				FOR cursor_brothers IN
					(SELECT m_id
					FROM cp_mer
					WHERE mer_parent =
						(SELECT mer_node
						FROM cp_mer
						WHERE m_id = cursor_mer_id_parent))
				LOOP
					/*новое название*/
					cursor_mer_code2 := cursor_mer_code || '.' || TO_CHAR(n);

					/*переименовывание*/
					UPDATE cp_mer
					SET mer_code = cursor_mer_code2
					WHERE m_id = cursor_brothers.m_id;

					cursor_mer_code2 := cursor_mer_code;
					n := n + 1;

				END LOOP;

			/*если "братьев" = 1*/
			ELSE

				/*id МБ*/
				SELECT m_id
					INTO cursor_mer_id_brother
				FROM cp_mer
				WHERE mer_parent =
					(SELECT mer_node
					FROM cp_mer
					WHERE m_id = cursor_mer_id_parent);

				/*потомки МБ*/
				SELECT COUNT(*)
					INTO cursor_exist_child_mer
				FROM cp_mer
				WHERE mer_parent =
					(SELECT mer_node FROM cp_mer
					WHERE m_id = cursor_mer_id_brother);

				/*если есть потомки МБ*/
				IF cursor_exist_child_mer = 0 THEN

					/*МБ становится родительским мероприятием*/
					UPDATE mer_to_usr
					SET mer_id = cursor_mer_id_parent
					WHERE mer_id = cursor_mer_id_brother;

					/*если нет потомков МБ*/
				ELSE
					/*Все поддерево, начиная с МБ поднимается на 1 уровень выше*/
					/*необходимо организовать 2 цикла
					первый-обход с максимального концевого мероприятия до родителя 
					удаляемого мероприятия
					второй-внутренний цикл по "братьям" каждого родительского мер-ия*/

					/*длина поддерева*/
					SELECT MAX(LEVEL)
						INTO cursor_level
					FROM cp_mer
					START WITH m_id = cursor_mer_id
					CONNECT BY mer_parent = PRIOR mer_node;

					/*цикл по уровням*/
					FOR n IN 1..cursor_level 
					LOOP

						/*цикл по "братьям"*/
						FOR cursor_brothers IN
							(SELECT m_id
							FROM cp_mer
							WHERE LEVEL = n
							START WITH m_id = cursor_mer_id
							CONNECT BY mer_parent = PRIOR mer_node)

						LOOP
							/*переобозначение кодов мероприятий*/

							/*пересчет сумм. сумма МР переходит в оставшееся МБ, остальные
							суммы не изменяются*/
							null;


						END LOOP;

					END LOOP;

				END IF;

			END IF;

		/*==================================================================*/
		END IF;

		/*удалим пользователей, которые были данном мероприятии*/
		DELETE FROM mer_to_usr
		WHERE mer_id IN
				(SELECT m_id FROM cp_mer
				START WITH m_id = cursor_mer_id
				CONNECT BY mer_parent = PRIOR mer_node);

	END IF;

END DEL_MER;
/
PROMPT CREATE FUNCTION "UPD_FIN_MER"
create or replace PROCEDURE UPD_FIN_MER
/*обновление суммы в мероприятии. если обновляем в мероприятии-потомке,
то просто обновляем. если обновляем в каком-либо мероприятии-родителе,
то учитываем тип финансирования родителя*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_fin IN cp_mer.fin%TYPE) IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_fin cp_mer.fin%TYPE;
		cursor_sum_brother cp_mer.fin%TYPE;
		cursor_parent_fin cp_mer.fin%TYPE;
		cursor_param_mer_code cp_mer.mer_code%TYPE;
		cursor_param_mer_code2 cp_mer.mer_code%TYPE;
		cursor_param_fin cp_mer.fin%TYPE;
BEGIN
	/*если есть данное мероприятие*/
	IF READ_COUNT_MER(param_mer_name, param_mer_code) = 1 THEN

		SELECT CHECK_FINANCE(param_mer_name, param_mer_code, param_fin)
			INTO cursor_fin
		FROM dual;

		IF param_fin <= cursor_fin THEN

			SELECT READ_MID_MER(param_mer_name, param_mer_code)
				INTO cursor_mer_id
			FROM dual;

			UPDATE cp_mer
			SET fin = param_fin
			WHERE m_id = cursor_mer_id;

			/*переопределим мероприятие*/
			SELECT mer_code
				INTO cursor_param_mer_code
			FROM cp_mer
			WHERE m_id = READ_PARENT_MER(param_mer_name, param_mer_code);

			SELECT READ_MID_MER(param_mer_name, cursor_param_mer_code)
				INTO cursor_mer_id
			FROM dual;

			/*сумма родителя*/
			SELECT fin
				INTO cursor_parent_fin
			FROM cp_mer
			WHERE m_id = cursor_mer_id;

			/*сумма другого потомка*/
			SELECT READ_SUM_BROTHERS_MER(param_mer_name, param_mer_code)
				INTO cursor_sum_brother
			FROM dual;

			SELECT param_fin
				INTO cursor_param_fin
			FROM dual;

			cursor_param_fin := cursor_param_fin + cursor_sum_brother;

			WHILE cursor_param_fin > cursor_parent_fin
			LOOP

				SELECT READ_MID_MER(param_mer_name, cursor_param_mer_code)
					INTO cursor_mer_id
				FROM dual;

				UPDATE cp_mer
				SET fin = cursor_param_fin
				WHERE m_id = cursor_mer_id;

				SELECT READ_SUM_BROTHERS_MER(param_mer_name, cursor_param_mer_code)
					INTO cursor_sum_brother
				FROM dual;

				SELECT cursor_param_mer_code
					INTO cursor_param_mer_code2
				FROM dual;

				/*поднимемся на 1 уровень вверх*/
				SELECT mer_code
					INTO cursor_param_mer_code
				FROM cp_mer
				WHERE m_id = READ_PARENT_MER(param_mer_name, cursor_param_mer_code2);

				/*сумма родителя*/
				SELECT fin 
					INTO cursor_parent_fin
				FROM cp_mer
				WHERE m_id = READ_MID_MER(param_mer_name, cursor_param_mer_code);

				cursor_param_fin := cursor_param_fin + cursor_sum_brother;

			END LOOP;

		END IF;
	END IF;
END UPD_FIN_MER;
/
PROMPT CREATE PROCEDURE "ADD_USR_TO_MER"
CREATE OR REPLACE PROCEDURE ADD_USR_TO_MER
/*добавление участника в мероприятие*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_username IN cp_users.user_name%TYPE,
	param_fin IN cp_mer.fin%TYPE) IS
		cursor_mer_id cp_mer.m_id%TYPE;
		cursor_user_id cp_users.user_id%TYPE;
		cursor_child_mer NUMBER;
		cursor_mer_code1 cp_mer.mer_code%TYPE;
		cursor_mer_code2 cp_mer.mer_code%TYPE;
		cursor_cp cp_mer.cp%TYPE;
		cursor_year_start cp_mer.year_start%TYPE;
		cursor_year_stop cp_mer.year_stop%TYPE;
		cursor_fin cp_mer.fin%TYPE;
		cursor_type_fin cp_mer.type_fin%TYPE;
BEGIN
	SELECT user_id
		INTO cursor_user_id
	FROM cp_users
	WHERE user_name = param_username;

	/*наличие в базе данного участника*/
	IF cursor_user_id > 0 THEN
		SELECT READ_MID_MER(param_mer_name, param_mer_code)
			INTO cursor_mer_id
		FROM dual;

		/*проверим наличие в базе данного мероприятия*/
		IF cursor_mer_id > 0 THEN
		/*проверим, есть ли какой-либо участник в данном мероприятии.
		если нет - то обновим мероприятие на данного участника.
		Если есть - проверим, связан ли он с данным мероприятием*/
			/*при наличии у мероприятия потомка, нельзя добавить
			участника.*/
			SELECT READ_COUNT_CHILD_MER(param_mer_name, param_mer_code)
				INTO cursor_child_mer
			FROM dual;
			IF cursor_child_mer = 0 THEN

			/*проверим наличие участника в мероприятии*/
				IF READ_COUNT_USR_MER(param_mer_name, param_mer_code) > 0 THEN

					/*если нет данного участника в данном мероприятии*/
					IF READ_EXISTS_USR_MER(param_mer_name, param_mer_code, param_username) = 0 THEN
						SELECT fin
							INTO cursor_fin
						FROM cp_mer
						WHERE m_id = cursor_mer_id;

						/*проверка добавляемой суммы*/
						IF param_fin < cursor_fin THEN

							/*определим переменные*/
							cursor_fin := cursor_fin - param_fin;
							cursor_mer_code1:=param_mer_code ||'.1';
							cursor_mer_code2:=param_mer_code ||'.2';
							SELECT cp
								INTO cursor_cp
							FROM cp_mer
							WHERE m_id = cursor_mer_id;
							SELECT year_start
								INTO cursor_year_start
							FROM cp_mer
							WHERE m_id = cursor_mer_id;
							SELECT year_stop
								INTO cursor_year_stop
							FROM cp_mer
							WHERE m_id = cursor_mer_id;
							SELECT type_fin
								INTO cursor_type_fin
							FROM cp_mer
							WHERE m_id = cursor_mer_id;

							/*перенесем уже существующего участника в мероприятие - потомок*/
							ADD_MER
								(param_mer_name,
								cursor_mer_code1,
								param_mer_name,
								param_mer_code,
								cursor_cp,
								cursor_year_start,
								cursor_year_stop,
								cursor_fin,
								cursor_type_fin);

								/*данные в mer_to_usr обновятся в процедуре ADD_MER*/

							/*добавим нового участника*/
							ADD_MER
								(param_mer_name,
								cursor_mer_code2,
								param_mer_name,
								param_mer_code,
								cursor_cp,
								cursor_year_start,
								cursor_year_stop,
								param_fin,
								cursor_type_fin);

								/*обновим данные в mer_to_usr*/
								INSERT INTO mer_to_usr
								VALUES(	mer_to_usr_seq.nextval,
										READ_MID_MER(param_mer_name, cursor_mer_code2),
										cursor_user_id);
						END IF;
					END IF;
				/*если нет участников - добавим*/
				ELSE

					/*добавим в таблицу связи запись мероприятие-участник*/
					INSERT INTO mer_to_usr
					VALUES(mer_to_usr_seq.nextval, cursor_mer_id, cursor_user_id);

					/*обновим сумму в мероприятии*/
					UPD_FIN_MER(param_mer_name, param_mer_code, param_fin);
				END IF;
			END IF;
		END IF;
	END IF;
END ADD_USR_TO_MER;
/
PROMPT CREATE PROCEDURE "DEL_USR_IN_MER"
CREATE OR REPLACE PROCEDURE DEL_USR_IN_MER
/*удаление участника из мероприятия*/
/*ПЕРЕДАЕЛАТЬ!!!*/
	(param_mer_name IN cp_mer.mer_name%TYPE,
	param_mer_code IN cp_mer.mer_code%TYPE,
	param_username IN cp_users.user_name%TYPE) IS
	cursor_mer_id cp_mer.m_id%TYPE;
	cursor_user_id cp_users.user_id%TYPE;
BEGIN
	IF READ_END_MER(param_mer_name, param_mer_code) = 1 THEN
		SELECT READ_MID_MER(param_mer_name, param_mer_code)
			INTO cursor_mer_id
		FROM dual;
		SELECT user_id
			INTO cursor_user_id
		FROM cp_users 
		WHERE user_name = param_username;
		IF READ_EXISTS_USR_MER(	param_mer_name,
								param_mer_code,
								param_username) = 1 THEN
			DELETE FROM mer_to_usr
			WHERE	mer_id = cursor_mer_id AND
					usr_id = cursor_user_id;
		END IF;
	END IF;
END DEL_USR_IN_MER;
/
PROMPT CREATE PROCEDURE "UPD_USR_IN_MER"
CREATE OR REPLACE PROCEDURE UPD_USR_IN_MER
/*обновление участника в мероприятии*/
	(param_mer_name 		IN	cp_mer.mer_name%TYPE,
	param_mer_code 		IN	cp_mer.mer_code%TYPE,
	param_username_old 	IN	cp_users.user_name%TYPE,
	param_username_new 	IN	cp_users.user_name%TYPE) IS
	cursor_mer_id			cp_mer.m_id%TYPE;
	cursor_user_id_old		cp_users.user_id%TYPE;
	cursor_user_id_new		cp_users.user_id%TYPE;
BEGIN
	SELECT READ_MID_MER(param_mer_name, param_mer_code)
		INTO cursor_mer_id
	FROM dual;
	SELECT user_id
		INTO cursor_user_id_old
	FROM cp_users 
	WHERE user_name = param_username_old;
	SELECT user_id
		INTO cursor_user_id_new
	FROM cp_users 
	WHERE user_name = param_username_new;
	IF	READ_EXISTS_USR_MER(	param_mer_name,
								param_mer_code,
								param_username_old) = 1 AND
		READ_EXISTS_USR_MER(	param_mer_name,
								param_mer_code,
								param_username_new) = 0
	THEN
		UPDATE mer_to_usr
		SET usr_id  = cursor_user_id_new
		WHERE	mer_id = cursor_mer_id AND
				usr_id = cursor_user_id_old;
	END IF;
END UPD_USR_IN_MER;
/