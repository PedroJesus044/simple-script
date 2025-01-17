
#docker exec owncloud_mariadb mariadb -u owncloud -powncloud owncloud -e "select * from oc_users"

docker exec -i owncloud_mariadb mariadb -u owncloud -powncloud owncloud << "EOF"
DELIMITER $$
CREATE OR REPLACE TRIGGER restricter_trigger AFTER INSERT
    ON oc_activity FOR EACH ROW
    BEGIN
            DECLARE admin INT;
            DECLARE q_fileid INT;
            DECLARE q_type varchar(255);
            DECLARE q_mimetype varchar(255);
            DECLARE this_activity_id INT;
            SET this_activity_id = NEW.activity_id;
            SET admin = (SELECT count(*) FROM oc_activity JOIN oc_group_user ON oc_activity.`user`  = oc_group_user.uid where oc_activity.`type` = 'file_created' and oc_activity.activity_id = this_activity_id and oc_group_user.gid='admin');
                SELECT oc_filecache.fileid, oc_activity.`type`, oc_mimetypes.mimetype
                INTO q_fileid, q_type, q_mimetype
                FROM oc_activity
                JOIN oc_filecache ON oc_activity.object_id = oc_filecache.fileid
                JOIN oc_mimetypes ON oc_mimetypes.id = oc_filecache.mimetype
                where oc_activity.`type` = 'file_created' and oc_activity.activity_id = this_activity_id;
            IF (admin=0)
            THEN
                        UPDATE oc_filecache
                        SET permissions = 21
                        WHERE fileid = q_fileid;
            END IF;
      END$$

CREATE OR REPLACE TRIGGER grant_admin_perms AFTER INSERT
    ON oc_group_user FOR EACH ROW
    BEGIN
            IF (NEW.gid = 'admin')
            THEN
                   #Actualiza todos los archivos de un usuario
                        UPDATE oc_filecache
                        JOIN oc_activity ON oc_activity.object_id = oc_filecache.fileid
                        JOIN oc_mimetypes ON oc_mimetypes.id = oc_filecache.mimetype
                        SET oc_filecache.permissions = 27
                                WHERE oc_activity.`user` = NEW.uid
                                AND oc_filecache.`path` != 'files'
                                AND oc_filecache.`path` NOT LIKE 'files_trashbin%'
                                #Busca que el mimetype no sea == 2 ya que ese id pertenece al de directorios
                                AND oc_mimetypes.id  != 2;

                        #Actualiza todos los directorios de un usuario
                        UPDATE oc_filecache
                        JOIN oc_activity ON oc_activity.object_id = oc_filecache.fileid
                        JOIN oc_mimetypes ON oc_mimetypes.id = oc_filecache.mimetype
                        SET oc_filecache.permissions = 31
                                WHERE oc_activity.`user` = NEW.uid
                                AND oc_filecache.`path` != 'files'
                                AND oc_filecache.`path` NOT LIKE 'files_trashbin%'
                                #Busca que el mimetype sea == 2 ya que ese id pertenece al de directorios
                                AND oc_mimetypes.id  = 2;
            END IF;
END$$

CREATE OR REPLACE TRIGGER revoke_admin_perms AFTER DELETE
    ON oc_group_user FOR EACH ROW
    BEGIN
            IF (OLD.gid = 'admin')
            THEN
               #Actualiza todos los archivos de un usuario
                        UPDATE oc_filecache
                        JOIN oc_activity ON oc_activity.object_id = oc_filecache.fileid
                        JOIN oc_mimetypes ON oc_mimetypes.id = oc_filecache.mimetype
                        SET oc_filecache.permissions = 21
                                WHERE oc_activity.`user` = OLD.uid
                                AND oc_filecache.`path` != 'files'
                                AND oc_filecache.`path` NOT LIKE 'files_trashbin%';
            END IF;
END$$
EOF

docker exec owncloud_mariadb mariadb -u owncloud -powncloud owncloud -e "SHOW TRIGGERS"
