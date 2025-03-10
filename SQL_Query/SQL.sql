-- 掲示板の投稿内容
create table boardcontents (
    postid integer primary key auto_increment,
    date DATETIME not null,
    ID integer not null,
    text VARCHAR(100) not null,
    foreign key (ID) references Customer(ID)
);
insert into boardcontents (date, ID, text)
values ('2023-11-16 11:00:14', 5, '新NISA「成長投資枠」使う？');
insert into boardcontents (date, ID, text)
values ('2023-11-16 11:00:50', 4, 'もちろん使うさ。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:39:46', 2, 'どんなメリットがあるの？');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:44:16', 5, '投資利益が無税になるんだよ。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:45:32', 1, 'それはいいね。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 14:54:31', 5, '新しい保険ができたよ！');
-- アカウントデータ用
drop table if exists customer;
create table customer (
    ID integer primary key auto_increment,
    login_id VARCHAR(100) not null unique,
    password VARCHAR(100) not null role VARCHAR(20) default "GENERAL"
);
insert into customer
values(null, 'ayukawa', 'SweetfishRevier1', 'GENERAL');
insert into customer
values(null, 'samejima', 'SharkIsaland2', 'GENERAL');
insert into customer
values(null, 'wanibuchi', 'CrocodileChasm3', 'GENERAL');
insert into customer
values(null, 'ebihara', 'ShrimpField4', 'GENERAL');
insert into customer
values(null, 'kanie', 'CrubBay5', 'GENERAL');
insert into customer
values(null, 'admin', 'Administrator35', 'ADMIN');
-- 正直リレーショナルにした意味は全然なかったいいね・よくないねタイプ
drop table if exists votetype;
create table votetype (
    typeid integer primary key auto_increment,
    typename VARCHAR(10) not null unique
);
insert into votetype
values(null, 'good');
insert into votetype
values(null, 'bad');
--  いいね、よくないねの投稿記録用
create table votelog (
    postid integer,
    ID integer not null,
    votetype integer not null,
    foreign key (postid) references boardcontents(postid),
    foreign key (ID) references customer(ID),
    foreign key (votetype) references votetype(typeid)
);
-- もしデータの削除を行いたい場合は、
-- boardcontents テーブルのデータを削除
-- delete from boardcontents;
-- alter table boardcontents auto_increment = 1;
-- 外部キー制約を再度有効にする
-- set foreign_key_checks = 1;
-- のように外部キー制約の解除が必要です