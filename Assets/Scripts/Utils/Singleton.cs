using UnityEngine;
using System.Collections;

/// <summary>
/// Be aware this will not prevent a non singleton constructor
///   such as `T myT = new T();`
/// To prevent that, add `protected T () {}` to your singleton class.
/// 
/// As a note, this is made as MonoBehaviour because we need Coroutines.
/// 
/// http://wiki.unity3d.com/index.php?title=Singleton
/// </summary>
public class MonoBehaviourSingleton<T> : MonoBehaviour where T : MonoBehaviour
{
    private static T _instance = null;

    //private static object _lock = new object();

    public static void InitSingleton()
    {
        //bool wasnull = false;
        if (_instance == null)
        {
            //wasnull = true;
            _instance = FindInstance(); // TODO: anything wrong with this? Should only need the Find if you start a new level and you carried the singleton over from the previous one. Right? You don't also need it in public static T Instance, right?
        }

        if (_instance == null)
        {
            _instance = CreateInstance(); //
        }


        /*
        if (_instance != null && wasnull)
        {
            Debug.Log("[Singleton] Created/found singleton instance (on GO: " + _instance.name + "): " + typeof(T).Name);
        }
        else if (_instance != null)
        {
            Debug.Log("[Singleton] Singleton Instance already present: (on GO: "+ _instance.name+"): " + typeof(T).Name );
        }
        else if (_instance == null)
        {
            Debug.LogWarning("[Singleton] Singleton instance could not be created! " + typeof(T).Name);
        }*/

    }

    void OnEnable()
    {
        Debug.Log("Enabling "+name);
        applicationIsQuitting = false;
        InitSingleton();
    }

    void Awake()
    {
        //applicationIsQuitting = false;
        InitSingleton();
        
    }

    public static T Instance
    {
        get
        {
            if (applicationIsQuitting)
            {
                Debug.LogWarning("[Singleton] Instance '" + typeof(T) +
                    "' already destroyed on application quit." +
                    " Won't create again - returning null.");
                return null;
            }

            //lock (_lock)//http://forum.unity3d.com/threads/unity-5-1-has-broken-the-use-of-singleton-patterns.332607/
            //{
                //if (_instance == null)
                //{
                    //_instance = FindInstance();can't call this from outside the unity main thread ? (moved to Awake)

                    //if (_instance == null)
                   // {
                   //     _instance = CreateInstance();
                   // }
                    //else
                   // {
  //                      Debug.Log("[Singleton] Using instance already created: " +
    //                                _instance.name);
                 //   }
                //}

                return _instance;
            //}
        }
    }

    private static T FindInstance()
    {
        Object[] objects = FindObjectsOfType(typeof(T));
        _instance = (T)objects[0];// FindObjectOfType(typeof(T));

        if (objects.Length == 1)
        {
            return _instance;
        }

        else if (objects.Length > 1)
        {
            Debug.LogError("[Singleton] Something went really wrong " +
                " - there should never be more than 1 singleton!" +
                " Reopening the scene might fix it.");
            return _instance;
        }
        
        else return null;
    }

    private static T CreateInstance()
    {
        GameObject singleton = new GameObject();
        _instance = singleton.AddComponent<T>();
        singleton.name = "(singleton) " + typeof(T).ToString();

        DontDestroyOnLoad(singleton);

        Debug.Log("[Singleton] An instance of " + typeof(T) +
            " is needed in the scene, so '" + singleton +
            "' was created with DontDestroyOnLoad.");
        return _instance;
    }

    private static bool applicationIsQuitting = false;
    /// <summary>
    /// When Unity quits, it destroys objects in a random order.
    /// In principle, a Singleton is only destroyed when application quits.
    /// If any script calls Instance after it have been destroyed, 
    ///   it will create a buggy ghost object that will stay on the Editor scene
    ///   even after stopping playing the Application. Really bad!
    /// So, this was made to be sure we're not creating that buggy ghost object.
    /// </summary>
    public void OnDestroy()
    {
        applicationIsQuitting = true;
    }
}




/// <summary>
/// Be aware this will not prevent a non singleton constructor
///   such as `T myT = new T();`
/// To prevent that, add `protected T () {}` to your singleton class.
/// 
/// As a note, this is made as MonoBehaviour because we need Coroutines.
/// 
/// http://wiki.unity3d.com/index.php?title=Singleton
/// </summary>
public class Singleton<T> : UnityEngine.Object where T : class, new()
{
    private static T _instance = default(T);

    //private static object _lock = new object();

    public static void Init()
    {

        if (_instance == null)
        {
            _instance = FindInstance(); // TODO: anything wrong with this? Should only need the Find if you start a new level and you carried the singleton over from the previous one. Right? You don't also need it in public static T Instance, right?
        }

        if (_instance == null)
        {
            _instance = CreateInstance(); //
        }
    }

    void Awake()
    {
        Init();
    }

    public static T Instance
    {
        get
        {
            if (applicationIsQuitting)
            {
                Debug.LogWarning("[Singleton] Instance '" + typeof(T) +
                    "' already destroyed on application quit." +
                    " Won't create again - returning null.");
                return default(T);
            }

            //lock (_lock)//http://forum.unity3d.com/threads/unity-5-1-has-broken-the-use-of-singleton-patterns.332607/
            //{
            //if (_instance == null)
            //{
            //_instance = FindInstance();can't call this from outside the unity main thread ? (moved to Awake)

            //if (_instance == null)
            // {
            //     _instance = CreateInstance();
            // }
            //else
            // {
            //                      Debug.Log("[Singleton] Using instance already created: " +
            //                                _instance.name);
            //   }
            //}

            return _instance;
            //}
        }
    }

    private static T FindInstance()
    {
        Object[] objects = FindObjectsOfType(typeof(T));
        _instance = objects[0] as T;// FindObjectOfType(typeof(T));

        if (objects.Length == 1)
        {
            return _instance;
        }

        else if (objects.Length > 1)
        {
            Debug.LogError("[Singleton] Something went really wrong " +
                " - there should never be more than 1 singleton!" +
                " Reopening the scene might fix it.");
            return _instance;
        }

        else return null;
    }

    private static T CreateInstance()
    {
        //GameObject singleton = new GameObject();
        _instance = new T();
        //singleton.name = "(singleton) " + typeof(T).ToString();

        //DontDestroyOnLoad(singleton);

        Debug.Log("[Singleton] An instance of " + typeof(T) +
            " is needed in the scene, so a static instance was created in this non-monobehaviour class");
        return _instance;
    }

    private static bool applicationIsQuitting = false;
    /// <summary>
    /// When Unity quits, it destroys objects in a random order.
    /// In principle, a Singleton is only destroyed when application quits.
    /// If any script calls Instance after it have been destroyed, 
    ///   it will create a buggy ghost object that will stay on the Editor scene
    ///   even after stopping playing the Application. Really bad!
    /// So, this was made to be sure we're not creating that buggy ghost object.
    /// </summary>
    public void OnDestroy()
    {
        applicationIsQuitting = true;
    }
}