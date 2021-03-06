/*****************************************************************
*                            MADE BY
*
*   K   K   RRRRR    U     U     CCCCC    3333333      1   3333333
*   K  K    R    R   U     U    C     C         3     11         3
*   K K     R    R   U     U    C               3    1 1         3
*   KK      RRRRR    U     U    C           33333   1  1     33333
*   K K     R        U     U    C               3      1         3
*   K  K    R        U     U    C     C         3      1         3
*   K   K   R         UUUUU U    CCCCC    3333333      1   3333333
*
******************************************************************
*                       AMX MOD X Script                         *
*     You can modify the code, but DO NOT modify the author!     *
******************************************************************
*
* Description:
* ============
* This is a plugin for Counte-Strike 1.6's Zombie Plague Mod which allows you to buy, launch atom bomb and kill all the zombies.
*
*****************************************************************/

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <zombieplague>

new const g_item_name[] = { "ATOM Bomb" }
const g_item_cost = 100

new const p_satchel_radio[] = "models/p_satchel_radio.mdl"
new const v_satchel_radio[] = "models/v_satchel_radio.mdl"

new const sound_jet[] = "ambience/jetflyby1.wav"
new const sound_explode[] = "weapons/explode3.wav"
new const sound_explode2[] = "weapons/explode4.wav"
new const sound_explode3[] = "weapons/explode5.wav"
new const sound_pickup[] = "items/9mmclip2.wav"
new const sound_deploy[][] = { "items/gunpickup3.wav", "items/gunpickup4.wav" }

enum
{
	radio_idle1 = 0,
	radio_fidget1,
	radio_draw,
	radio_fire,
	radio_holster
}

new g_itemid_atom_bomb, g_MsgScreenShake, g_MsgSync, g_MsgCurWeapon
new g_has_atom_bomb[33], g_has_atom_radio[33], can[32]
new Float:g_timedelay[33]

public plugin_init()
{
	register_plugin("[ZP] Extra: ATOM Bomb", "1.0", "kpuc313")
	
	g_itemid_atom_bomb = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN)	
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_RadioDeploy", 1)
	
	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgScreenShake = get_user_msgid("ScreenShake")
	g_MsgSync = CreateHudSyncObj()
}

public plugin_precache() {
	static i
	for(i = 0; i < sizeof sound_deploy; i++)	
	precache_sound(sound_deploy[i])
	precache_model(p_satchel_radio)
	precache_model(v_satchel_radio)
	precache_sound(sound_pickup)
	precache_sound(sound_jet)
	precache_sound(sound_explode)
	precache_sound(sound_explode2)
	precache_sound(sound_explode3)
}

public zp_extra_item_selected(player, itemid) {
	if (itemid == g_itemid_atom_bomb) {
		g_has_atom_bomb[player] = true
		
		set_hudmessage(255, 0, 0, -1.0, 0.20, 1, 6.0, 6.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(player, g_MsgSync, "Press +attack2 for change the Knife^ninto a Zombie ATOM Bomb Radio!")
		emit_sound(player, CHAN_VOICE, sound_pickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

}

public zp_user_infected_post(id, infector) {
	g_has_atom_bomb[id] = false
	g_has_atom_radio[id] = false
	can[id] = false
	reset_user_knife(id)
}

public zp_user_humanized_post(id, survivor) {
	can[id] = true
}

public fw_RadioDeploy(iEnt) {
	new id = get_pdata_cbase(iEnt, 41, 5)

	if (g_has_atom_bomb[id] && g_has_atom_radio[id])
	{
		ChangeModelsRadio(id)

		UTIL_PlayWeaponAnimation(id, radio_draw)

		set_pdata_float(iEnt, 46, 9999.0, 4);

		set_pdata_float(id, 83, 9999.0);
	}
}

public fw_CmdStart(id, uc_handle, seed) {
	if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !g_has_atom_bomb[id])
		return FMRES_IGNORED

	static Float:gametime; gametime = get_gametime()
	new weapon = get_user_weapon(id)
	new buttons = get_uc(uc_handle, UC_Buttons)
	
	if (weapon != CSW_KNIFE)
		return FMRES_IGNORED
		
	if(g_has_atom_radio[id]) {
		if (buttons & IN_ATTACK)
		{	
			buttons &= ~IN_ATTACK
			set_uc(uc_handle, UC_Buttons, buttons)
		
			if(!can[id])
				return FMRES_IGNORED
		
			set_user_godmode(id, 1)
			UTIL_PlayWeaponAnimation(id, radio_fire)
			call(id)
		}
	}
	if (buttons & IN_ATTACK2)
	{
		buttons &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, buttons)
		
		if(g_timedelay[id] < gametime) {
			if (!g_has_atom_radio[id])
			{
				g_has_atom_radio[id] = true
				ChangeModelsRadio(id)
				UTIL_PlayWeaponAnimation(id, radio_draw)
				client_print(id, print_center, "Changed to Zombie ATOM Bomb Radio")
				
			} else {
				g_has_atom_radio[id] = false
				reset_user_knife(id)
				client_print(id, print_center, "Changed to Knife")
			}
			emit_sound(id, CHAN_VOICE, sound_deploy[random_num(0, sizeof sound_deploy - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			g_timedelay[id] = gametime + 0.5
		}
	}
		
	return FMRES_IGNORED
}

public can_command(id) if(is_user_connected(id)) can[id] = true

public event_round_start() {
	new players[32], num
	get_players(players,num,"h")
	for(new i=0;i<num;i++) {
		g_has_atom_bomb[players[i]] = false
		g_has_atom_radio[players[i]] = false
		can[players[i]] = false
		set_user_godmode(players[i], 0)
		g_timedelay[players[i]] = 0.0
		remove_task(players[i])
		set_task(12.0,"can_command",players[i])
	}
}

public call(id) {
	new name[32]
	get_user_name(id, name, charsmax(name))
	
	set_hudmessage(255, 0, 0, -1.0, 0.20, 1, 6.0, 6.0, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%s called for Zombie ATOM Bomb^nall zombies will die!", name)
	client_cmd(0, "spk %s", sound_jet)
	set_task(6.5, "explode", id)
	set_task(7.0, "atombomb", id)
	
	can[id] = false
}

public explode(id) {
	client_cmd(0, "spk %s", sound_explode)
	client_cmd(0, "spk %s", sound_explode2)
	client_cmd(0, "spk %s", sound_explode3)
}

public atombomb(id) {
	if (!is_user_alive(id) || !g_has_atom_bomb[id])
		return;

	new count = zp_get_zombie_count()
	set_pev(id, pev_frags, float(pev(id, pev_frags) + count))
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + count)
	
	new players[32], num
	get_players(players,num,"h")	
	for(new i=0;i<num;i++)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenShake, _, players[i])
		write_short((1<<14)*2)
		write_short((1<<14)*2)
		write_short((1<<14)*2)
		message_end();
		
		if(zp_get_user_zombie(players[i])) {
			user_kill(players[i])
		}
	}
}

public reset_user_knife(id)
{
	ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(FM_NULLENT, "weapon_knife", id))
	
	engclient_cmd(id, "weapon_knife")
	emessage_begin(MSG_ONE, g_MsgCurWeapon, _, id)
	ewrite_byte(1)
	ewrite_byte(CSW_KNIFE)
	ewrite_byte(0)
	emessage_end()
}

stock ChangeModelsRadio(id)
{
	set_pev(id, pev_viewmodel2, v_satchel_radio)
	set_pev(id, pev_weaponmodel2, p_satchel_radio)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
}
