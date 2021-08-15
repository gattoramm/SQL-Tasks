Условия:

Даны следующие таблицы : клиенты (100 записей), документы (2 тыс. записей) и операции (2 млн. записей)
```sql
CREATE TABLE Clients
(
  ClientId Int PRIMARY KEY,
  LastName VarChar(50)
)
;
CREATE TABLE Documents
(
  DocId    Int PRIMARY KEY,
  ClientId Int REFERENCES Clients(ClientId),
  Date     Date,
  Type     Char(1),
  Number   VarChar(50),
  Serial   VarChar(50)
)
;
CREATE TABLE Transactions
(
  TranId   Int PRIMARY KEY NONCLUSTERED,
  ClientId Int REFERENCES Clients(ClientId),
  Date     DateTime,
  Type     Char(1),
  Sum      Numeric(18, 1),
  Currency Char(3)
)
CREATE CLUSTERED INDEX Transactions_IX ON Transactions ([ClientId], [Date], [TranId])
;
```
### Задачи:

1. Для каждого клиента вывести номер, серию и дату последнего по дате документа с типом 'P', а также сумму, тип, дату последней операции.
2. Вывести ежедневную сумму операций комиссии (Transactions.Type = 'C') c 20 апреля 2012 г. по 25 апреля 2012 г. включительно.
3. Требуется найти все максимально возможные непрерывные интервалы дат, в которых количество операций за день не меньше 60.

Решением каждой задачи должен быть запрос, максимально оптимальный по скорости выполнения и ресурсоёмкости. Приветствуются несколько вариантов решения.