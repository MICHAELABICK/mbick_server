import yaml

RCLONE_VOLUME_TYPE = "mount-dir"
def dict_with_keyval(dicts, key, value, dict_type = "dict"):
    for d in dicts:
        if d[key] == value:
            return d

    raise ValueError('{0} with {1} "{2}" does not exist'.format(dict_type, key, value))

class FilterModule(object):
    def filters(self):
        return {
            'user': self.user,
            'mount_dir_volumes': self.mount_dir_volumes,
            'named_volumes': self.named_volumes,
            'volume': self.volume,
            'volume_source': self.volume_source
        }

    def user(self, users, name):
        return dict_with_keyval(users, "name", name, "user")

    def mount_dir_volumes(self, volumes):
        mount_dir_types = ["mount-dir"];
        if RCLONE_VOLUME_TYPE == "mount-dir":
            mount_dir_types.append("rclone")

        mount_dir_vols = []
        for vol in volumes:
            if vol['type'] in mount_dir_types:
                mount_dir_vols.append(vol)

        return mount_dir_vols

    def named_volumes(self, volumes):
        bind_types = ["mount-dir", "bind"]
        if RCLONE_VOLUME_TYPE is in bind_types:
            bind_types.append("rclone")

        named_vols = []
        for vol in volumes:
            if vol['type'] not in bind_types:
                named_vols.append(vol)

        return named_vols

    def volume_source(self, volumes, name, mount_dir):
        vol = self.volume(volumes, name)

        vol_type = vol['type']
        if vol_type == "rclone":
            vol_type = RCLONE_VOLUME_TYPE

        if vol_type == "mount-dir":
            return "{0}/{1}".format(mount_dir, vol['name'])
        elif vol_type == "bind":
            try:
                return vol['source']
            except KeyError:
                raise KeyError('bind mounted volume "{0}" does not contain the key "source"'.format(vol['name']))
        else:
            # otherwise it is some sort of named volume
            return vol['name']

    def volume(self, volumes, name):
        return dict_with_keyval(volumes, "name", name, "volume")
