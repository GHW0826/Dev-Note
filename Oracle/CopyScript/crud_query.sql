
-- Create Table
CREATE TABLE emp 
( 
    empno       NUMBER(4)	NOT NULL,
    ename       VARCHAR2(10),
    job         VARCHAR2(9),
    mgr         NUMBER(4),
    hiredate    DATE,
    sal         NUMBER(7,2),
    comm        NUMBER(7,2),
    deptno      NUMBER(2)
);

-- Create Table with PK
CREATE TABLE emp 
( 
    empno       NUMBER(4)	NOT NULL,
    ename       VARCHAR2(10),
    job         VARCHAR2(9),
    mgr         NUMBER(4),
    hiredate    DATE,
    sal         NUMBER(7,2),
    comm        NUMBER(7,2),
    deptno      NUMBER(2),
     CONSTRAINT emp_pk PRIMARY KEY (empno)
);

-- Create Table CTAS
CREATE TABLE T
AS SELECT d.no, e.*
FROM scott.emp e, 
(SELECT rownum no from dual connect by level <= 1000) d;

-- Create PK
ALTER TABLE emp ADD CONSTRAINT emp_pk PRIMARY KEY (empno);

-- Create Index
CREATE INDEX emp_idx01 ON emp(job, deptno);

-- Create Table Comment
COMMENT ON TABLE emp IS '사원정보';

-- Create Column Comment
COMMENT ON COLUMN emp.empno IS '사원번호';



-- Insert CRow
INSERT INTO emp 
VALUES(7839, 'KING', 'PRESIDENT', NULL, TO_DATE('1981-11-17', 'yyyy-mm-dd'), 5000, NULL, 10);