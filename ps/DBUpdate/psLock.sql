create table [dbo].[psLock]
(
 [psKey] char(8) not null,
 [psWho] varchar(1024),

 constraint [psLock_pk] primary key 
  ([psKey])
)

grant delete, insert, references, select, update on [dbo].[psLock]
 to public
 ==
 insert into psLock values ('LOCK','LockTest')
 update psLock set psWho='Lock Test' where psKey='LOCK'
 delete from psLock where psKey='LOCK'