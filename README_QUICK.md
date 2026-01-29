# UNISOC AVB2 Firmware Re-signing

## Tu Configuración

**Particiones con chain descriptors en vbmeta:**
- boot + dtbo (misma clave: `54eda733...`)
- recovery (clave diferente: `0be51f63...`)
- vbmeta_system → product + system
- vbmeta_vendor → vendor
- Modem partitions (l_modem, l_ldsp, l_gdsp, pm_sys)
- socko, odmko

## Archivos Modificados

### Scripts
1. **sign_modified.sh** - Script principal con soporte para vbmeta_system/vendor
2. **sign_avb_enhanced.sh** - Firma AVB mejorada con extracción de Props
3. **generate_vbmeta_with_chains.sh** - Genera vbmeta con chain descriptors

### Workflow
- **sign_complete_workflow.yml** - GitHub Actions para automatizar el proceso

## Uso Rápido

### GitHub Actions
1. Sube los scripts a tu repo en `main` branch
2. Ve a Actions → Run workflow
3. Pega URL del ZIP con tu firmware
4. Descarga `resigned.zip` de Releases

### Local
```bash
# Preparar
chmod +x *.sh
curl -o original.zip [URL_DE_TU_FIRMWARE]
curl -o avbtool.tgz https://android.googlesource.com/platform/external/avb/+archive/refs/heads/pie-release.tar.gz
curl -o magisk.apk [URL_MAGISK]

# Ejecutar
./sign_modified.sh
```

## ZIP de Input Debe Contener

```
splloader.bin (o u-boot-spl-16k-sign.bin)
uboot.bin
sml.bin
tos.bin (o trustos.bin)
teecfg.bin
boot.img
dtbo.img
recovery.img
vbmeta.img (o vbmeta-sign.img)
vbmeta_system.img
vbmeta_vendor.img
```

## Output

```
resigned.zip
└── output/
    ├── *-sign.bin (bootloader)
    ├── boot.img (con Magisk)
    ├── dtbo.img
    ├── recovery.img
    ├── vbmeta.img
    ├── vbmeta_system.img
    └── vbmeta_vendor.img
```

## Notas Importantes

- System/Product/Vendor images NO se modifican (solo sus vbmeta)
- Boot se parchea con Magisk automáticamente
- Requiere 4-5 pares de claves RSA4096
- Preserva rollback indexes originales
- Puede requerir wipe de userdata

## Ver COMPLETE_GUIDE.md para detalles técnicos
