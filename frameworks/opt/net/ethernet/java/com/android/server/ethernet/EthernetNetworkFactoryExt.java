/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.server.ethernet;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.DhcpResults;
import android.net.EthernetManager;
import android.net.IEthernetServiceListener;
import android.net.InterfaceConfiguration;
import android.net.IpConfiguration;
import android.net.IpConfiguration.IpAssignment;
import android.net.IpConfiguration.ProxySettings;
import android.net.LinkProperties;
import android.net.LinkAddress;
import android.net.NetworkAgent;
import android.net.NetworkCapabilities;
import android.net.NetworkFactory;
import android.net.NetworkInfo;
import android.net.NetworkInfo.DetailedState;
import android.net.NetworkUtils;
import android.net.StaticIpConfiguration;
import android.net.RouteInfo;
import android.os.Handler;
import android.os.IBinder;
import android.os.INetworkManagementService;
import android.os.Looper;
import android.os.RemoteCallbackList;
import android.os.RemoteException;
import android.os.ServiceManager;
import android.text.TextUtils;
import android.util.Log;
import android.content.Intent;
import android.os.UserHandle;
import android.provider.Settings;
import android.os.Message;
import android.os.HandlerThread;
import android.os.SystemProperties;
import android.net.ip.IIpClient;
import android.net.ip.IpClientCallbacks;
import android.net.ip.IpClientUtil;
import android.os.ConditionVariable;
import com.android.internal.util.IndentingPrintWriter;
import com.android.server.net.BaseNetworkObserver;

import java.io.FileDescriptor;
import java.io.PrintWriter;

import java.io.File;
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.Exception;
import java.util.List;
import java.net.InetAddress;
import java.net.Inet4Address;

import android.annotation.NonNull;
import android.annotation.Nullable;

import android.net.shared.ProvisioningConfiguration;
import static android.net.shared.LinkPropertiesParcelableUtil.toStableParcelable;

import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import android.net.LinkAddress;
import android.net.LinkProperties;
import java.net.UnknownHostException;

class EthernetNetworkFactoryExt {
    private static final String TAG = "EthernetNetworkFactoryExt";
    private static String mIface = "eth1";
    private static boolean mLinkUp = false;
    private static String mMode = "0"; // 0: DHCP; 1: Static
    private static final int EVENT_INTERFACE_LINK_STATE_CHANGED = 0;
    private static final int EVENT_INTERFACE_LINK_STATE_CHANGED_DELAY_MS = 1000;
    private static final boolean DBG = true;
    private static String mDns = "0.0.0.0,0.0.0.0,";
    
    private INetworkManagementService mNMService;
    private Context mContext;
    private Handler mHandler;
    private int mConnectState;  //0: disconnect ; 1: connect; 2: connecting

    private volatile @Nullable IIpClient mIpClient;
    private @Nullable IpClientCallbacksImpl mIpClientCallback;
    private @Nullable NetworkAgent mNetworkAgent;
    private @Nullable IpConfiguration mIpConfig;
    private StaticIpConfiguration mStaticIpConfiguration;

    private LinkProperties mLinkProperties;
    // private EthernetManager mEthernetManager;
    // private StaticIpConfiguration mStaticIpConfiguration;

	public EthernetNetworkFactoryExt() {
        Log.v(TAG,"EthernetNetworkFactoryExt _");
        mIface = SystemProperties.get("ro.net.eth_aux", "eth1");
        HandlerThread handlerThread = new HandlerThread("EthernetNetworkFactoryExtThread");
        handlerThread.start();
        mHandler = new EthernetNetworkFactoryExtHandler(handlerThread.getLooper(), this);
        mConnectState = 0;
        mIpClient = null;
	}

    public int mEthernetCurrentState = EthernetManager.ETHER_STATE_DISCONNECTED;
    public int ethCurrentIfaceState = EthernetManager.ETHER_IFACE_STATE_DOWN;

    private void sendEthernetStateChangedBroadcast(int curState) {
        mEthernetCurrentState = curState;
        final Intent intent = new Intent(EthernetManager.ETHERNET_STATE_CHANGED_ACTION);
        intent.addFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY_BEFORE_BOOT); 
        intent.putExtra(EthernetManager.EXTRA_ETHERNET_STATE, curState);
        intent.putExtra(EthernetManager.EXTRA_ETHERNET_IFACE, mIface);
        mContext.sendStickyBroadcastAsUser(intent, UserHandle.ALL);
    }
    private void sendEthIfaceStateChangedBroadcast(int curState) {
        final Intent intent = new Intent(EthernetManager.ETHERNET_IFACE_STATE_CHANGED_ACTION);
        intent.addFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY_BEFORE_BOOT);  //  
        intent.putExtra(EthernetManager.EXTRA_ETHERNET_IFACE_STATE, curState);
        intent.putExtra(EthernetManager.EXTRA_ETHERNET_IFACE, mIface);
        ethCurrentIfaceState = curState;
        // Settings.Secure.putInt(mContext.getContentResolver(),
        //                          Settings.Secure.ETHERNET_ON,
        //                          curState);

        mContext.sendStickyBroadcast(intent);
    }


    private static String sTcpBufferSizes = null;  // Lazy initialized.

    private class IpClientCallbacksImpl extends IpClientCallbacks {
        private final ConditionVariable mIpClientStartCv = new ConditionVariable(false);
        private final ConditionVariable mIpClientShutdownCv = new ConditionVariable(false);
        
            @Override
            public void onIpClientCreated(IIpClient ipClient) {
                mIpClient = ipClient;
                mIpClientStartCv.open();
            }

            private void awaitIpClientStart() {
                mIpClientStartCv.block();
            }

            private void awaitIpClientShutdown() {
                mIpClientShutdownCv.block();
            }

            @Override
            public void onProvisioningSuccess(LinkProperties newLp) {
                Log.d(TAG, "onProvisioningSuccess: lp = " + newLp);
                mLinkProperties = newLp;
                //mHandler.post(() -> onIpLayerStarted(newLp));
                mDns = "";
                for (InetAddress nameserver : mLinkProperties.getDnsServers()) {
                    mDns += nameserver.getHostAddress() + ",";
                }
            }

            @Override
            public void onProvisioningFailure(LinkProperties newLp) {
                 Log.d(TAG, "onProvisioningFailure: lp = " + newLp);
               // mHandler.post(() -> onIpLayerStopped(newLp));
            }

            @Override
            public void onLinkPropertiesChange(LinkProperties newLp) {
                 Log.d(TAG, "onLinkPropertiesChange: lp = " + newLp);
                //mHandler.post(() -> updateLinkProperties(newLp));
            }

            @Override
            public void onQuit() {
                mIpClient = null;
                mIpClientShutdownCv.open();
            }
        }

        private static void shutdownIpClient(IIpClient ipClient) {
            try {
                ipClient.shutdown();
            } catch (RemoteException e) {
                Log.e(TAG, "Error stopping IpClient", e);
            }
        } 


	private class EthernetNetworkFactoryExtHandler extends Handler {
		private EthernetNetworkFactoryExt mEthernetNetworkFactoryExt;
		
		public EthernetNetworkFactoryExtHandler(Looper looper, EthernetNetworkFactoryExt factory) {
			super(looper);
			mEthernetNetworkFactoryExt = factory;
		}
		
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
				case EVENT_INTERFACE_LINK_STATE_CHANGED:
					if(msg.arg1 == 1) {
						mEthernetNetworkFactoryExt.connect();
					} else {
						mEthernetNetworkFactoryExt.disconnect();
					}
				break;
			}
		}
	}

    private void setInterfaceUp(String iface) {
        try {
            mNMService.setInterfaceUp(iface);
        } catch (Exception e) {
            Log.e(TAG, "Error upping interface " + iface + ": " + e);
        }
    }
    
    private void addToLocalNetwork(String iface, List<RouteInfo> routes) {
		try {
			mNMService.addInterfaceToLocalNetwork(iface, routes);
		} catch (RemoteException e) {
			Log.e(TAG, "Failed to add iface to local network " + e);
		}
	}

    public void start(Context context, INetworkManagementService s) {
    	mContext = context;
    	mNMService = s;
       // mEthernetManager = (EthernetManager) context.getSystemService(Context.ETHERNET_SERVICE);
        try {
            final String[] ifaces = mNMService.listInterfaces();
            for (String iface : ifaces) {
                synchronized(this) {
                    if (mIface.equals(iface)) {
                        setInterfaceUp(iface);
                        break;
                    }
                }
            }
        } catch (RemoteException e) {
            Log.e(TAG, "Could not get list of interfaces " + e);
        }
    }
    
	public void interfaceLinkStateChanged(String iface, boolean up) {
		Log.d(TAG, "interfaceLinkStateChanged: iface = " + iface + ", up = " + up);
		if (!mIface.equals(iface))
			return;
		if (mLinkUp == up)
			return;

        if (up && getCarrierState(iface) != 1) {
            Log.d(TAG, iface + " fake link up");
            return;
        }

		mLinkUp = up;
		if (up) {
			mHandler.removeMessages(EVENT_INTERFACE_LINK_STATE_CHANGED);
			mHandler.sendMessageDelayed(mHandler.obtainMessage(EVENT_INTERFACE_LINK_STATE_CHANGED, 1, 0),
							EVENT_INTERFACE_LINK_STATE_CHANGED_DELAY_MS);
		} else {
			mHandler.removeMessages(EVENT_INTERFACE_LINK_STATE_CHANGED);
			mHandler.sendMessageDelayed(mHandler.obtainMessage(EVENT_INTERFACE_LINK_STATE_CHANGED, 0, 0),
							0);			
		}
	}
	

	private boolean startDhcp(String iface) {
		Log.d(TAG, "IpClient.startProvisioning");
		sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_CONNECTING);
		if (mIpClient != null) {
            if (DBG) Log.d(TAG, "IpClient already started,will shutdown old and creat new");
             try {
                mIpClient.shutdown();
            } catch (RemoteException e) {
                Log.e(TAG, "Error stopping IpClient", e);
            }
			mIpClient = null;
		}

        mIpClientCallback = new IpClientCallbacksImpl();
        IpClientUtil.makeIpClient(mContext,iface , mIpClientCallback);
        mIpClientCallback.awaitIpClientStart();

		mIpClientCallback.awaitIpClientStart();
        if (sTcpBufferSizes == null) {
            sTcpBufferSizes = mContext.getResources().getString(com.android.internal.R.string.config_ethernet_tcp_buffers);
        }

        mIpConfig = new IpConfiguration(IpAssignment.DHCP, ProxySettings.NONE, null, null);
        provisionIpClient(mIpClient, mIpConfig, sTcpBufferSizes);
		return true;
	}


    private static void provisionIpClient(IIpClient ipClient, IpConfiguration config,
                String tcpBufferSizes) {
            if (config.getProxySettings() == ProxySettings.STATIC ||
                    config.getProxySettings() == ProxySettings.PAC) {
                try {
                    ipClient.setHttpProxy(toStableParcelable(config.getHttpProxy()));
                } catch (RemoteException e) {
                    e.rethrowFromSystemServer();
                }
            }

            if (!TextUtils.isEmpty(tcpBufferSizes)) {
                try {
                    ipClient.setTcpBufferSizes(tcpBufferSizes);
                } catch (RemoteException e) {
                    e.rethrowFromSystemServer();
                }
            }

            final ProvisioningConfiguration provisioningConfiguration;
            if (config.getIpAssignment() == IpAssignment.STATIC) {
                provisioningConfiguration = new ProvisioningConfiguration.Builder()
                        .withStaticConfiguration(config.getStaticIpConfiguration())
                        .build();
            } else {
                provisioningConfiguration = new ProvisioningConfiguration.Builder()
                        .withProvisioningTimeoutMs(0)
                        .build();
            }

            try {
                ipClient.startProvisioning(provisioningConfiguration.toStableParcelable());
            } catch (RemoteException e) {
                e.rethrowFromSystemServer();
            }
        }
	
	private void stopDhcp(String iface) {
		if (mIpClient != null) {
            try {
                mIpClient.shutdown();
            } catch (RemoteException e) {
                Log.e(TAG, "Error stopping IpClient", e);
            }
			mIpClient = null;
		}
	}
	
        private void setStaticIpConfiguration(){
                
                mStaticIpConfiguration =new StaticIpConfiguration();
                
                String mIpAddress = "192.168.1.100";
                int mNetmask = 24;
                String mGateway = "192.168.1.1";
                String mDns1 = "192.168.1.1";
                String mDns2 = "8.8.8.8";
                
                String mProStaticInfo = SystemProperties.get("persist.eth.ext.staticinfo", null);
                if(!TextUtils.isEmpty(mProStaticInfo)){
                        String mStaticInfo[] = mProStaticInfo.split(",");
                        mIpAddress = mStaticInfo[0];
                        mNetmask =  Integer.parseInt(mStaticInfo[1]);
                        if(!TextUtils.isEmpty(mStaticInfo[2]) && !TextUtils.isEmpty(mStaticInfo[3])) {
                                mGateway = mStaticInfo[2];
                                mDns1 = mStaticInfo[3];
                        }
                        if(!TextUtils.isEmpty(mStaticInfo[4]))
                                mDns2 = mStaticInfo[4];

                        mDns = "";
                        mDns = mDns1 + "," + mDns2 + ",";
                }else{
                    SystemProperties.set("persist.eth.ext.staticinfo","192.168.1.100,24,192.168.1.1,192.168.1.1,8.8.8.8");
                }
                
                Inet4Address inetAddr = getIPv4Address(mIpAddress);
                int prefixLength = mNetmask;
                InetAddress gatewayAddr =getIPv4Address(mGateway); 
                InetAddress dnsAddr = getIPv4Address(mDns1);
                
                mStaticIpConfiguration.ipAddress = new LinkAddress(inetAddr, prefixLength);
                
               // eth1 used in LAN, not need gateway dns
               /*
                mStaticIpConfiguration.gateway=gatewayAddr;
                mStaticIpConfiguration.dnsServers.add(dnsAddr);
                mStaticIpConfiguration.dnsServers.add(getIPv4Address(mDns2));
              */
        }
        
        private boolean setStaticIpAddress(StaticIpConfiguration staticConfig) {
                if (DBG) Log.d(TAG, "setStaticIpAddress:" + staticConfig);
                if (staticConfig.ipAddress != null ) {
                        try {
                                Log.i(TAG, "Applying static IPv4 configuration to " + mIface + ": " + staticConfig);
                                InterfaceConfiguration config = mNMService.getInterfaceConfig(mIface);
                                config.setLinkAddress(staticConfig.ipAddress);
                                mNMService.setInterfaceConfig(mIface, config);
                                return true;
                        } catch(RemoteException|IllegalStateException e) {
                                Log.e(TAG, "Setting static IP address failed: " + e.getMessage());
                        }
                } else {
                        Log.e(TAG, "Invalid static IP configuration.");
                }
                return false;
        }
	
        private void startDhcpServer() {
                if (DBG) Log.d(TAG, "startDhcpServer");
                String startIp = SystemProperties.get("persist.dhcpserver.start", "192.168.1.150");
                String endIp = SystemProperties.get("persist.dhcpserver.end", "192.168.1.250");
                String[] dhcpRange = {startIp, endIp};
                try {
                        mNMService.tetherInterface(mIface);
                        mNMService.startTethering(dhcpRange);
                } catch (Exception e) {
                        Log.e(TAG, "Error tether interface " + mIface + ": " + e);
                }              
        }
        
        private void stopDhcpServer() {
                if (DBG) Log.d(TAG, "stopDhcpServer");
                try {
                        mNMService.stopTethering();
                } catch (Exception e) {
                        Log.e(TAG, "Error tether stop interface " + mIface + ": " + e);
                }
                        
        }
        
	private void connect() {
		Thread connectThread = new Thread(new Runnable() {
			public void run() {
				if (mConnectState == 1) {
					Log.d(TAG, "already connected, skip");
					return;
				}
                mConnectState = 2;
				mMode = SystemProperties.get("persist.eth.ext.mode", "0");
				if (mMode.equals("0")) { // DHCP
					if (!startDhcp(mIface)) {
						Log.e(TAG, "startDhcp failed for " + mIface);
						mConnectState = 0;
                        sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_DISCONNECTED);
						return;
					}
					Log.d(TAG, "startDhcp success for " + mIface);
                    sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_CONNECTED);					
				} else { // Static
                    setStaticIpConfiguration();
                    if (!setStaticIpAddress(mStaticIpConfiguration)) {
                        // We've already logged an error.
                        if (DBG) Log.i(TAG, "setStaticIpAddress error,set again");
                        try {
                            Thread.sleep(200);    
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        } 
                        
                        if (!setStaticIpAddress(mStaticIpConfiguration)) {
                            mConnectState = 0;
                            sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_DISCONNECTED);
                            return;
                        }
                    }
                    
                    mLinkProperties = mStaticIpConfiguration.toLinkProperties(mIface);
                                        
                    //add dhcpserver
                    if (SystemProperties.get("persist.dhcpserver.enable", "0").equals("1")) {
                        startDhcpServer();
                    }

                    sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_CONNECTED);
				}
                
                /*
                //add static route
                String gw = getGateway();
                mLinkProperties.addRoute(new RouteInfo(new LinkAddress(NetworkUtils.numericToInetAddress("10.80.71.0"), 24), NetworkUtils.numericToInetAddress(gw)));

                // addInterfaceToLocalNetwork
                if (mLinkProperties != null) {
                    List<RouteInfo> routes = mLinkProperties.getRoutes();
                    addToLocalNetwork(mIface, routes);
                }
                */

                mConnectState = 1;
			}
		});
		connectThread.start();
	}
	
	private void disconnect() {
		Thread disconnectThread = new Thread(new Runnable() {
			public void run() {
				if (mConnectState == 0) {
					Log.d(TAG, "already disconnected, skip");
					return;
				}
				mMode = SystemProperties.get("persist.eth.ext.mode", "0");
				if (mMode.equals("0")) { // DHCP
					stopDhcp(mIface);
				} else {
                        if (SystemProperties.get("persist.dhcpserver.enable", "0").equals("1")) {
                            stopDhcpServer();
                        }
                }
				try {
					mNMService.clearInterfaceAddresses(mIface);
				} catch (Exception e) {
					Log.e(TAG, "Failed to clear addresses " + e);
				}
				mConnectState = 0;
                sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_DISCONNECTED);
			}
		});
		disconnectThread.start();
	}	
	
	public void interfaceAdded(String iface) {
		Log.d(TAG, "interfaceAdded: iface = " + iface);
		if (!mIface.equals(iface))
			return;
		setInterfaceUp(mIface);
		mLinkUp = false;
	}
	
	public void interfaceRemoved(String iface) {
		Log.d(TAG, "interfaceRemoved: iface = " + iface);
		if (!mIface.equals(iface))
			return;
		mLinkUp = false;
		mHandler.removeMessages(EVENT_INTERFACE_LINK_STATE_CHANGED);
		disconnect();
	}
        
        private Inet4Address getIPv4Address(String text) {
                try {
                        return (Inet4Address) NetworkUtils.numericToInetAddress(text);
                } catch (IllegalArgumentException|ClassCastException e) {
                        return null;
                }
        }
        
         public String getGateway() {
                if (null == mLinkProperties)
                    return "";
                if (null == mLinkProperties.getRoutes())
                    return "";

                for (RouteInfo route : mLinkProperties.getRoutes()) {
                        if (route.hasGateway()) {
                                InetAddress gateway = route.getGateway();
                                if (route.isIPv4Default()) {
                                        return gateway.getHostAddress();
                                }
                        }
                }
                return "";		
    }
        
    /*
     * return dns format: "8.8.8.8,4.4.4.4"
     */
    String getDns() {
        //Log.d(TAG, "dns: " + mDns);
        return mDns;
    }

    public void updateIpConfiguration(String iface, IpConfiguration ipConfiguration) {
        boolean state = false;

        if (!mIface.equals(iface))
			return;

        if (Settings.System.getInt(mContext.getContentResolver(),Settings.System.AUX_ETHERNET_ON,1) == 0) {
            Log.d(TAG, iface +" is disabled, skip");
            return;
        }

        if (ipConfiguration.getIpAssignment() == IpAssignment.STATIC) {
            StaticIpConfiguration staticIpConfiguration = ipConfiguration.getStaticIpConfiguration();
            if (staticIpConfiguration != null) {
                setStaticIpConfiguration();
                state = setStaticIpAddress(staticIpConfiguration);
                try {
                    Thread.sleep(300);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                mLinkProperties = mStaticIpConfiguration.toLinkProperties(iface);
            }
        } else {
            state = startDhcp(iface);
        }

        if(state) {
            sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_CONNECTED);
        } else {
            sendEthernetStateChangedBroadcast(EthernetManager.ETHER_STATE_DISCONNECTED);
        }
    }

    public String getIpAddress(String iface) {
        if (!mIface.equals(iface))
			return "";

        NetworkInterface netface = null;
        try {
            netface = NetworkInterface.getByName(iface);
        } catch (SocketException ex) {
            Log.w(TAG, "Could not obtain address of network interface " + iface, ex);
            return "";
        }

        Enumeration<InetAddress> addrs = netface.getInetAddresses();
        while (addrs.hasMoreElements()) {
            InetAddress addr = addrs.nextElement();
            if (addr instanceof Inet4Address) {
                //ipv4
                return addr.getHostAddress();
            }
        }

        return "";
    }

    public String getNetmask(String iface) {
        if (!mIface.equals(iface))
			return "";

        NetworkInterface netface = null;
        try {
            netface = NetworkInterface.getByName(iface);
            //ipv4
            int preLen = netface.getInterfaceAddresses().get(1).getNetworkPrefixLength();
            return getNetmaskByPrefixLength(preLen);
        } catch (SocketException ex) {
            Log.w(TAG, "Could not obtain address of network interface " + iface, ex);
            return "";
        }
    }

    public String getNetmaskByPrefixLength(int length) {
        int mask = 0xffffffff << (32 - length);
        int partsNum = 4;
        int bitsOfPart = 8;
        int maskParts[] = new int[partsNum];
        int selector = 0x000000ff;

        for (int i = 0; i < maskParts.length; i++) {
            int pos = maskParts.length - 1 - i;
            maskParts[pos] = (mask >> (i * bitsOfPart)) & selector;
        }

        String result = "";
        result = result + maskParts[0];
        for (int i = 1; i < maskParts.length; i++) {
            result = result + "." + maskParts[i];
        }
        return result;
    }

    public String getSubnetAddress(String ip, String mask) {
        String result = "";
        try {
            // calc sub-net IP
            InetAddress ipAddress = InetAddress.getByName(ip);
            InetAddress maskAddress = InetAddress.getByName(mask);

            byte[] ipRaw = ipAddress.getAddress();
            byte[] maskRaw = maskAddress.getAddress();

            int unsignedByteFilter = 0x000000ff;
            int[] resultRaw = new int[ipRaw.length];
            for (int i = 0; i < resultRaw.length; i++) {
                resultRaw[i] = (ipRaw[i] & maskRaw[i] & unsignedByteFilter);
            }

            // make result string
            result = result + resultRaw[0];
            for (int i = 1; i < resultRaw.length; i++) {
                result = result + "." + resultRaw[i];
            }
        } catch (UnknownHostException e) {
            e.printStackTrace();
        }

        return result;
    }

    private String ReadFromFile(File file) {
        if((file != null) && file.exists()) {
            try {
                FileInputStream fin= new FileInputStream(file);
                BufferedReader reader= new BufferedReader(new InputStreamReader(fin));
                String flag = reader.readLine();
                fin.close();
                return flag;
            } catch(Exception e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    int getCarrierState(String ifname) {
        if(ifname != "") {
            try {
                File file = new File("/sys/class/net/" + ifname + "/carrier");
                String carrier = ReadFromFile(file);
                return Integer.parseInt(carrier);
            } catch(Exception e) {
                e.printStackTrace();
                return 0;
            }
        } else {
            return 0;
        }
    }

}
