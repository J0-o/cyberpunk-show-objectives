module SimplyShowNearbyObjectives

public class ObjectiveSettings {
  public static func Get() -> ref<ObjectiveSettings> {
    return new ObjectiveSettings();
  }

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "General")
  @runtimeProperty("ModSettings.displayName", "Number of icons")
  @runtimeProperty("ModSettings.description", "Maximum number of nearby objective icons shown at once.")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "10")
  let maxIcons: Int32 = 3;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Quests")
  let showQuests: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Gigs")
  let showGigs: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Cyberpsycho Sightings")
  let showCyberpsychos: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "NCPD Scanner Hustles")
  let showNCPDScannerHustles: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Reported Crime")
  let showReportedCrime: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Assault in Progress")
  let showAssaults: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simply Show Nearby Objectives")
  @runtimeProperty("ModSettings.category", "Objective Types")
  @runtimeProperty("ModSettings.displayName", "Suspected Criminal Activity")
  let showCriminalActivities: Bool = true;

}

public abstract class ObjectiveFilter extends IScriptable {
  public static func IsActivityVariant(variant: gamedataMappinVariant) -> Bool {
    return Equals(variant, gamedataMappinVariant.DefaultQuestVariant)
      || Equals(variant, gamedataMappinVariant.Zzz06_NCPDGigVariant)
      || Equals(variant, gamedataMappinVariant.GangWatchVariant)
      || Equals(variant, gamedataMappinVariant.OutpostVariant)
      || Equals(variant, gamedataMappinVariant.MinorActivityVariant)
      || Equals(variant, gamedataMappinVariant.HuntForPsychoVariant)
      || Equals(variant, gamedataMappinVariant.BountyHuntVariant)
      || Equals(variant, gamedataMappinVariant.QuestGiverVariant)
      || Equals(variant, gamedataMappinVariant.RetrievingVariant)
      || Equals(variant, gamedataMappinVariant.ClientInDistressVariant)
      || Equals(variant, gamedataMappinVariant.SabotageVariant)
      || Equals(variant, gamedataMappinVariant.ThieveryVariant)
      || Equals(variant, gamedataMappinVariant.CourierVariant)
      || Equals(variant, gamedataMappinVariant.ConvoyVariant);
  }

  public static func IsEnabledVariant(variant: gamedataMappinVariant) -> Bool {
    let settings: ref<ObjectiveSettings> = ObjectiveSettings.Get();
    return settings.showQuests
        && Equals(variant, gamedataMappinVariant.DefaultQuestVariant)
      || settings.showNCPDScannerHustles
        && Equals(variant, gamedataMappinVariant.Zzz06_NCPDGigVariant)
      || settings.showAssaults
        && Equals(variant, gamedataMappinVariant.GangWatchVariant)
      || settings.showCriminalActivities
        && Equals(variant, gamedataMappinVariant.OutpostVariant)
      || settings.showReportedCrime
        && Equals(variant, gamedataMappinVariant.MinorActivityVariant)
      || settings.showCyberpsychos
        && Equals(variant, gamedataMappinVariant.HuntForPsychoVariant)
      || settings.showGigs
        && (Equals(variant, gamedataMappinVariant.BountyHuntVariant)
          || Equals(variant, gamedataMappinVariant.QuestGiverVariant)
          || Equals(variant, gamedataMappinVariant.RetrievingVariant)
          || Equals(variant, gamedataMappinVariant.ClientInDistressVariant)
          || Equals(variant, gamedataMappinVariant.SabotageVariant)
          || Equals(variant, gamedataMappinVariant.ThieveryVariant)
          || Equals(variant, gamedataMappinVariant.CourierVariant)
          || Equals(variant, gamedataMappinVariant.ConvoyVariant));
  }

  public static func IsSupported(mappin: wref<IMappin>, variant: gamedataMappinVariant) -> Bool {
    let questMappin: ref<QuestMappin>;

    if !IsDefined(mappin)
      || !ObjectiveFilter.IsActivityVariant(variant) {
      return false;
    };
    questMappin = mappin as QuestMappin;
    if IsDefined(questMappin) && questMappin.IsUIAnimation() {
      return false;
    };
    return true;
  }

  public static func IsEligible(mappin: wref<IMappin>, variant: gamedataMappinVariant) -> Bool {
    return ObjectiveFilter.IsSupported(mappin, variant)
      && ObjectiveFilter.IsEnabledVariant(variant)
      && !mappin.IsPlayerTracked();
  }

}

public class ObjectiveSelector extends ScriptableSystem {
  private let m_controllers: array<wref<QuestMappinController>>;
  private let m_selected: array<wref<QuestMappinController>>;

  private func OnAttach() -> Void {
    ModSettings.RegisterListenerToModifications(this);
  }

  private func OnDetach() -> Void {
    ModSettings.UnregisterListenerToModifications(this);
  }

  public func OnModSettingsChange() -> Void {
    this.ApplySelection();
  }

  public static func Get() -> ref<ObjectiveSelector> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance())
      .Get(n"SimplyShowNearbyObjectives.ObjectiveSelector") as ObjectiveSelector;
  }

  public func Register(controller: ref<QuestMappinController>) -> Void {
    let i: Int32 = ArraySize(this.m_controllers) - 1;
    while i >= 0 {
      if !IsDefined(this.m_controllers[i]) {
        ArrayErase(this.m_controllers, i);
      } else {
        if this.m_controllers[i] == controller {
          return;
        };
      };
      i -= 1;
    };

    ArrayPush(this.m_controllers, controller);
    this.ApplySelection();
  }

  public func Unregister(controller: ref<QuestMappinController>) -> Void {
    let changed: Bool;
    let i: Int32 = ArraySize(this.m_controllers) - 1;
    while i >= 0 {
      if !IsDefined(this.m_controllers[i]) || this.m_controllers[i] == controller {
        ArrayErase(this.m_controllers, i);
        changed = true;
      };
      i -= 1;
    };

    i = ArraySize(this.m_selected) - 1;
    while i >= 0 {
      if !IsDefined(this.m_selected[i]) || this.m_selected[i] == controller {
        ArrayErase(this.m_selected, i);
        changed = true;
      };
      i -= 1;
    };

    if changed {
      this.ApplySelection();
    };
  }

  public func ApplyVisibility(controller: ref<QuestMappinController>) -> Void {
    if IsDefined(controller) && controller.RNOShouldManageVisibility() {
      controller.RNOApplySelection(
        this.IsSelected(controller) && !this.ShouldHideAll()
      );
    };
  }

  private func ShouldHideAll() -> Bool {
    let i: Int32;
    while i < ArraySize(this.m_controllers) {
      if IsDefined(this.m_controllers[i])
        && this.m_controllers[i].RNOIsTrackedDestinationNearby() {
        return true;
      };
      i += 1;
    };
    return false;
  }

  private func ApplySelection() -> Void {
    let candidates: array<wref<QuestMappinController>>;
    let i: Int32;
    let maxIcons: Int32 = ObjectiveSettings.Get().maxIcons;
    let selectedIndex: Int32;
    let shouldHide: Bool;

    i = ArraySize(this.m_selected) - 1;
    while i >= 0 {
      if !IsDefined(this.m_selected[i]) || !this.m_selected[i].RNOCanRemainSelected() {
        ArrayErase(this.m_selected, i);
      };
      i -= 1;
    };

    while ArraySize(this.m_selected) > maxIcons {
      ArrayErase(this.m_selected, ArraySize(this.m_selected) - 1);
    };

    i = 0;
    while i < ArraySize(this.m_controllers) {
      if IsDefined(this.m_controllers[i])
        && this.m_controllers[i].RNOIsCandidate()
        && !this.IsSelected(this.m_controllers[i]) {
        ArrayPush(candidates, this.m_controllers[i]);
      };
      i += 1;
    };

    while ArraySize(this.m_selected) < maxIcons && ArraySize(candidates) > 0 {
      selectedIndex = RandRange(0, ArraySize(candidates));
      ArrayPush(this.m_selected, candidates[selectedIndex]);
      ArrayErase(candidates, selectedIndex);
    };

    shouldHide = this.ShouldHideAll();

    i = 0;
    while i < ArraySize(this.m_controllers) {
      if IsDefined(this.m_controllers[i])
        && this.m_controllers[i].RNOShouldManageVisibility() {
        this.m_controllers[i].RNOApplySelection(
          this.IsSelected(this.m_controllers[i]) && !shouldHide
        );
      };
      i += 1;
    };
  }

  public func IsSelected(controller: ref<QuestMappinController>) -> Bool {
    let i: Int32;
    while i < ArraySize(this.m_selected) {
      if IsDefined(this.m_selected[i]) && this.m_selected[i] == controller {
        return true;
      };
      i += 1;
    };
    return false;
  }
}

@wrapMethod(WorldMappinsContainerController)
public func CreateMappinUIProfile(
  mappin: wref<IMappin>,
  mappinVariant: gamedataMappinVariant,
  customData: ref<MappinControllerCustomData>
) -> MappinUIProfile {
  if ObjectiveFilter.IsSupported(mappin, mappinVariant)
    && !mappin.IsPlayerTracked() {
    return MappinUIProfile.Create(
      r"base\\gameplay\\gui\\widgets\\mappins\\quest\\default_mappin.inkwidget",
      t"MappinUISpawnProfile.SSNOObjectiveRange",
      t"WorldMappinUIProfile.Quest"
    );
  };

  return wrappedMethod(mappin, mappinVariant, customData);
}

@wrapMethod(QuestMappinController)
protected cb func OnIntro() -> Bool {
  let selector: ref<ObjectiveSelector>;
  let result: Bool = wrappedMethod();

  selector = ObjectiveSelector.Get();
  if IsDefined(selector)
    && ObjectiveFilter.IsSupported(this.m_mappin, this.m_mappin.GetVariant()) {
    selector.Register(this);
  };
  return result;
}

@wrapMethod(QuestMappinController)
protected cb func OnUninitialize() -> Bool {
  let selector: ref<ObjectiveSelector> = ObjectiveSelector.Get();
  if IsDefined(selector) {
    selector.Unregister(this);
  };
  return wrappedMethod();
}

@wrapMethod(QuestMappinController)
private func UpdateVisibility() -> Void {
  let selector: ref<ObjectiveSelector>;
  wrappedMethod();

  selector = ObjectiveSelector.Get();
  if IsDefined(selector) {
    selector.ApplyVisibility(this);
  };
}

@addMethod(QuestMappinController)
public func RNOIsEligible() -> Bool {
  return ObjectiveFilter.IsEligible(this.m_mappin, this.m_mappin.GetVariant());
}

@addMethod(QuestMappinController)
public func RNOShouldManageVisibility() -> Bool {
  return ObjectiveFilter.IsSupported(this.m_mappin, this.m_mappin.GetVariant())
    && !this.m_mappin.IsPlayerTracked();
}

@addMethod(QuestMappinController)
private func RNODistanceToPlayer() -> Float {
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  if !IsDefined(player) {
    return 999999.0;
  };
  return Vector4.Distance(player.GetWorldPosition(), this.m_mappin.GetWorldPosition());
}

@addMethod(QuestMappinController)
private func RNOIsActive() -> Bool {
  let variant: gamedataMappinVariant = this.m_mappin.GetVariant();
  let isActiveOnWorldMap: Bool = this.m_questMappin == null
    || this.m_questMappin.IsActive()
    || !Equals(variant, gamedataMappinVariant.DefaultQuestVariant);
  return isActiveOnWorldMap
    && !this.m_isCompletedPhase;
}

@addMethod(QuestMappinController)
public func RNOIsTrackedDestinationNearby() -> Bool {
  return this.m_mappin.IsPlayerTracked()
    && this.RNODistanceToPlayer() <= 20.0;
}

@addMethod(QuestMappinController)
public func RNOIsCandidate() -> Bool {
  return this.RNOIsEligible()
    && this.RNOIsActive()
    && this.RNODistanceToPlayer() <= 200.0;
}

@addMethod(QuestMappinController)
public func RNOCanRemainSelected() -> Bool {
  return ObjectiveFilter.IsSupported(this.m_mappin, this.m_mappin.GetVariant())
    && ObjectiveFilter.IsEnabledVariant(this.m_mappin.GetVariant())
    && this.RNOIsActive()
    && this.RNODistanceToPlayer() <= 300.0;
}

@addMethod(QuestMappinController)
public func RNOApplySelection(selected: Bool) -> Void {
  this.SetRootVisible(selected && this.RNOIsActive());
}

@if(ModuleExists("LimitedHudCommon"))
@wrapMethod(QuestMappinController)
public func DetermineCurrentVisibility() -> Bool {
  let result: Bool = wrappedMethod();
  let selector: ref<ObjectiveSelector> = ObjectiveSelector.Get();
  if IsDefined(selector) && this.RNOShouldManageVisibility() {
    selector.ApplyVisibility(this);
    return true;
  };
  return result;
}
