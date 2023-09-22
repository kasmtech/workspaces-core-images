#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

LOCALES_RHEL="glibc-langpack-aa glibc-langpack-af glibc-langpack-agr glibc-langpack-ak glibc-langpack-am glibc-langpack-an glibc-langpack-anp glibc-langpack-ar glibc-langpack-as glibc-langpack-ast glibc-langpack-ayc glibc-langpack-az glibc-langpack-be glibc-langpack-bem glibc-langpack-ber glibc-langpack-bg glibc-langpack-bhb glibc-langpack-bho glibc-langpack-bi glibc-langpack-bn glibc-langpack-bo glibc-langpack-br glibc-langpack-brx glibc-langpack-bs glibc-langpack-byn glibc-langpack-ca glibc-langpack-ce glibc-langpack-chr glibc-langpack-cmn glibc-langpack-crh glibc-langpack-cs glibc-langpack-csb glibc-langpack-cv glibc-langpack-cy glibc-langpack-da glibc-langpack-de glibc-langpack-doi glibc-langpack-dsb glibc-langpack-dv glibc-langpack-dz glibc-langpack-el glibc-langpack-en glibc-langpack-eo glibc-langpack-es glibc-langpack-et glibc-langpack-eu glibc-langpack-fa glibc-langpack-ff glibc-langpack-fi glibc-langpack-fil glibc-langpack-fo glibc-langpack-fr glibc-langpack-fur glibc-langpack-fy glibc-langpack-ga glibc-langpack-gd glibc-langpack-gez glibc-langpack-gl glibc-langpack-gu glibc-langpack-gv glibc-langpack-ha glibc-langpack-hak glibc-langpack-he glibc-langpack-hi glibc-langpack-hif glibc-langpack-hne glibc-langpack-hr glibc-langpack-hsb glibc-langpack-ht glibc-langpack-hu glibc-langpack-hy glibc-langpack-ia glibc-langpack-id glibc-langpack-ig glibc-langpack-ik glibc-langpack-is glibc-langpack-it glibc-langpack-iu glibc-langpack-ja glibc-langpack-ka glibc-langpack-kab glibc-langpack-kk glibc-langpack-kl glibc-langpack-km glibc-langpack-kn glibc-langpack-ko glibc-langpack-kok glibc-langpack-ks glibc-langpack-ku glibc-langpack-kw glibc-langpack-ky glibc-langpack-lb glibc-langpack-lg glibc-langpack-li glibc-langpack-lij glibc-langpack-ln glibc-langpack-lo glibc-langpack-lt glibc-langpack-lv glibc-langpack-lzh glibc-langpack-mag glibc-langpack-mai glibc-langpack-mfe glibc-langpack-mg glibc-langpack-mhr glibc-langpack-mi glibc-langpack-miq glibc-langpack-mjw glibc-langpack-mk glibc-langpack-ml glibc-langpack-mn glibc-langpack-mni glibc-langpack-mr glibc-langpack-ms glibc-langpack-mt glibc-langpack-my glibc-langpack-nan glibc-langpack-nb glibc-langpack-nds glibc-langpack-ne glibc-langpack-nhn glibc-langpack-niu glibc-langpack-nl glibc-langpack-nn glibc-langpack-nr glibc-langpack-nso glibc-langpack-oc glibc-langpack-om glibc-langpack-or glibc-langpack-os glibc-langpack-pa glibc-langpack-pap glibc-langpack-pl glibc-langpack-ps glibc-langpack-pt glibc-langpack-quz glibc-langpack-raj glibc-langpack-ro glibc-langpack-ru glibc-langpack-rw glibc-langpack-sa glibc-langpack-sah glibc-langpack-sat glibc-langpack-sc glibc-langpack-sd glibc-langpack-se glibc-langpack-sgs glibc-langpack-shn glibc-langpack-shs glibc-langpack-si glibc-langpack-sid glibc-langpack-sk glibc-langpack-sl glibc-langpack-sm glibc-langpack-so glibc-langpack-sq glibc-langpack-sr glibc-langpack-ss glibc-langpack-st glibc-langpack-sv glibc-langpack-sw glibc-langpack-szl glibc-langpack-ta glibc-langpack-tcy glibc-langpack-te glibc-langpack-tg glibc-langpack-th glibc-langpack-the glibc-langpack-ti glibc-langpack-tig glibc-langpack-tk glibc-langpack-tl glibc-langpack-tn glibc-langpack-to glibc-langpack-tpi glibc-langpack-tr glibc-langpack-ts glibc-langpack-tt glibc-langpack-ug glibc-langpack-uk glibc-langpack-unm glibc-langpack-ur glibc-langpack-uz glibc-langpack-ve glibc-langpack-vi glibc-langpack-wa glibc-langpack-wae glibc-langpack-wal glibc-langpack-wo glibc-langpack-xh glibc-langpack-yi glibc-langpack-yo glibc-langpack-yue glibc-langpack-yuw glibc-langpack-zh glibc-langpack-zu"

LOCALES_UBUNTU="language-pack-af language-pack-am language-pack-an language-pack-ar language-pack-as language-pack-ast language-pack-az language-pack-be language-pack-bg language-pack-bn language-pack-br language-pack-bs language-pack-ca language-pack-crh language-pack-cs language-pack-cy language-pack-da language-pack-de language-pack-dz language-pack-el language-pack-en language-pack-eo language-pack-es language-pack-et language-pack-eu language-pack-fa language-pack-fi language-pack-fr language-pack-fur language-pack-ga language-pack-gd language-pack-gl language-pack-gu language-pack-he language-pack-hi language-pack-hr language-pack-hu language-pack-ia language-pack-id language-pack-is language-pack-it language-pack-ja language-pack-ka language-pack-kk language-pack-km language-pack-kn language-pack-ko language-pack-ku language-pack-lt language-pack-lv language-pack-mk language-pack-ml language-pack-mr language-pack-ms language-pack-my language-pack-nb language-pack-nds language-pack-ne language-pack-nl language-pack-nn language-pack-oc language-pack-or language-pack-pa language-pack-pl language-pack-pt language-pack-ro language-pack-ru language-pack-si language-pack-sk language-pack-sl language-pack-sq language-pack-sr language-pack-sv language-pack-ta language-pack-te language-pack-tg language-pack-th language-pack-tr language-pack-ug language-pack-uk language-pack-vi language-pack-xh language-pack-zh-hans language-pack-zh-hant"

LOCALES="aa_DJ aa_ER aa_ET af_ZA am_ET an_ES ar_AE ar_BH ar_DZ ar_EG ar_IN ar_IQ ar_JO ar_KW ar_LB ar_LY ar_MA ar_OM ar_QA ar_SA ar_SD ar_SY ar_TN ar_YE as_IN ast_ES ayc_PE az_AZ be_BY bem_ZM ber_DZ ber_MA bg_BG bho_IN bn_BD bn_IN bo_CN bo_IN br_FR brx_IN bs_BA byn_ER ca_AD ca_ES ca_FR ca_IT crh_UA csb_PL cs_CZ cv_RU cy_GB da_DK de_AT de_BE de_CH de_DE de_LU doi_IN dv_MV dz_BT el_CY el_GR en_AG en_AU en_BW en_CA en_DK en_GB en_HK en_IE en_IN en_NG en_NZ en_PH en_SG en_US en_ZA en_ZM en_ZW es_AR es_BO es_CL es_CO es_CR es_CU es_DO es_EC es_ES es_GT es_HN es_MX es_NI es_PA es_PE es_PR es_PY es_SV es_US es_UY es_VE et_EE eu_ES fa_IR ff_SN fi_FI fil_PH fo_FO fr_BE fr_CA fr_CH fr_FR fr_LU fur_IT fy_DE fy_NL ga_IE gd_GB gez_ER gez_ET gl_ES gu_IN gv_GB ha_NG he_IL hi_IN hne_IN hr_HR hsb_DE ht_HT hu_HU hy_AM ia_FR id_ID ig_NG ik_CA is_IS it_CH it_IT iu_CA ja_JP ka_GE kk_KZ kl_GL km_KH kn_IN kok_IN ko_KR ks_IN ku_TR kw_GB ky_KG lb_LU lg_UG li_BE lij_IT li_NL lo_LA lt_LT lv_LV mag_IN mai_IN mg_MG mhr_RU mi_NZ mk_MK ml_IN mni_IN mn_MN mr_IN ms_MY mt_MT my_MM nb_NO nds_DE nds_NL ne_NP nhn_MX niu_NU niu_NZ nl_AW nl_BE nl_NL nn_NO nr_ZA nso_ZA oc_FR om_ET om_KE or_IN os_RU pa_IN pa_PK pl_PL ps_AF pt_BR pt_PT ro_RO ru_RU ru_UA rw_RW sa_IN sat_IN sc_IT sd_IN se_NO shs_CA sid_ET si_LK sk_SK sl_SI so_DJ so_ET so_KE so_SO sq_AL sq_MK sr_ME sr_RS ss_ZA st_ZA sv_FI sv_SE sw_KE sw_TZ szl_PL ta_IN ta_LK te_IN tg_TJ th_TH ti_ER ti_ET tig_ER tk_TM tl_PH tn_ZA tr_CY tr_TR ts_ZA tt_RU ug_CN uk_UA unm_US ur_IN ur_PK uz_UZ ve_ZA vi_VN wa_BE wae_CH wal_ET wo_SN xh_ZA yi_US yo_NG yue_HK zh_CN zh_HK zh_SG zh_TW zu_ZA"

echo "Installing fonts and languages"
if [[ "${DISTRO}" == "oracle7" ]]; then
  yum-config-manager --enable ol7_optional_latest
  yum install -y \
    google-noto-emoji-fonts \
    google-noto-sans-cjk-fonts \
    google-noto-sans-fonts 
elif [[ "${DISTRO}" == "centos" ]]; then
  yum install -y \
    google-noto-emoji-fonts \
    google-noto-sans-cjk-fonts \
    google-noto-sans-fonts 
elif [[ "${DISTRO}" == @(fedora37|fedora38) ]]; then
  dnf install -y \
    glibc-locale-source \
    google-noto-cjk-fonts \
    google-noto-emoji-fonts \
    google-noto-sans-fonts \
    ${LOCALES_RHEL}
  for LOCALE in ${LOCALES}; do
    echo "Generating Locale for ${LOCALE}"
    localedef -i ${LOCALE} -f UTF-8 ${LOCALE}.UTF-8
  done
elif [[ "${DISTRO}" == @(oracle8|oracle9|rockylinux9|rockylinux8|almalinux9|almalinux8) ]]; then
  dnf install -y \
    glibc-locale-source \
    google-noto-emoji-fonts \
    google-noto-sans-cjk-ttc-fonts \
    google-noto-sans-fonts \
    ${LOCALES_RHEL}
  for LOCALE in ${LOCALES}; do
    echo "Generating Locale for ${LOCALE}"
    localedef -i ${LOCALE} -f UTF-8 ${LOCALE}.UTF-8
  done
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper addrepo -G \
    https://download.opensuse.org/repositories/M17N:/fonts/15.5/ fonts-x86_64
  zypper install -ny \
    glibc-i18ndata \
    glibc-locale \
    google-noto-coloremoji-fonts \
    google-noto-sans-cjk-fonts \
    noto-sans-fonts
  for LOCALE in ${LOCALES}; do
    echo "Generating Locale for ${LOCALE}"
    localedef -i ${LOCALE} -f UTF-8 ${LOCALE}.UTF-8
  done
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache \
    font-noto-all \
    font-noto-cjk \
    font-noto-emoji
elif [[ "${DISTRO}" == @(debian|parrotos5|kali) ]]; then
  apt-get update
  apt-get install -y \
    fonts-noto-core \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    locales-all
  for LOCALE in ${LOCALES}; do
    echo "Generating Locale for ${LOCALE}"
    localedef -i ${LOCALE} -f UTF-8 ${LOCALE}.UTF-8
  done
elif $(grep -q Bionic /etc/os-release); then
  apt-get update
  apt-get install -y \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-noto-hinted \
    fonts-noto-unhinted \
    ${LOCALES_UBUNTU}
else
  apt-get update
  apt-get install -y \
    fonts-noto-core \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    ${LOCALES_UBUNTU}
fi
