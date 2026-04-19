import React from 'react';
import { NavigationContainer, DarkTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { StatusBar } from 'expo-status-bar';

import LoginScreen from './screens/LoginScreen';
import NotesScreen from './screens/NotesScreen';
import TasksScreen from './screens/TasksScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

const SomNoteTheme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    primary: '#FFA500', // Glowing orange
    background: '#0a0a0a', // Deep black
    card: '#1c1c1c', // Dark grey cards
    text: '#ffffff',
    border: '#333333',
    notification: '#FF8C00',
  },
};

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;

          if (route.name === 'Notes') {
            iconName = focused ? 'document-text' : 'document-text-outline';
          } else if (route.name === 'Tasks') {
            iconName = focused ? 'checkmark-done-circle' : 'checkmark-done-circle-outline';
          }

          return <Ionicons name={iconName} size={size + 4} color={color} />;
        },
        tabBarActiveTintColor: '#FFA500',
        tabBarInactiveTintColor: '#888888',
        tabBarStyle: {
          backgroundColor: '#111111',
          borderTopColor: '#222222',
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        headerStyle: {
          backgroundColor: '#111111',
          shadowColor: 'transparent',
          elevation: 0,
        },
        headerTitleStyle: {
          fontWeight: 'bold',
          fontSize: 20,
        },
        headerTintColor: '#FFA500',
      })}
    >
      <Tab.Screen name="Notes" component={NotesScreen} options={{ title: 'My Notes' }} />
      <Tab.Screen name="Tasks" component={TasksScreen} options={{ title: 'My Tasks / Shaqooyinka' }} />
    </Tab.Navigator>
  );
}

export default function App() {
  return (
    <NavigationContainer theme={SomNoteTheme}>
      <StatusBar style="light" />
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Login" component={LoginScreen} />
        <Stack.Screen name="Main" component={MainTabs} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
