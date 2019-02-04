import yaml

def dict_with_keyval(dicts, key, value, dict_type = "dict"):
    for d in dicts:
        if d[key] == value:
            return d

    raise ValueError('{0} with {1} "{2}" does not exist'.format(dict_type, key, value))

class FilterModule(object):
    def filters(self):
        return {
                'user': self.user,
                'named_volumes': self.named_volumes,
                'volume': self.volume,
                'volume_source': self.volume_source
            }

    def user(self, users, name):
        return dict_with_keyval(users, "name", name, "user")

    def named_volumes(self, volumes):
        named_vols = []
        for vol in volumes:
            if vol['type'] not in ["mount-dir", "bind"]:
                named_vols.append(vol)

        return named_vols

    def volume_source(self, volumes, name, mount_dir):
        vol = self.volume(volumes, name)

        if vol['type'] == "mount-dir":
            return "{0}/{1}".format(mount_dir, vol['name'])
        elif vol['type'] == "bind":
            return vol['source']
        else:
            # otherwise it is some sort of named volume
            return vol['name']

    def volume(self, volumes, name):
        return dict_with_keyval(volumes, "name", name, "volume")
