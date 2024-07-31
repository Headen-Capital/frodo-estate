
import { Col, Layout, Row } from 'antd'
import { useRouter } from 'next/navigation'
import { ReactNode } from 'react'
import { Leftbar } from './leftBar'
import { Logo } from './logo'
import { DesignSystem } from './layoutProvider'
// import { SubNavigation } from './SubNavigation'
// import { Topbar } from './components/Topbar/index.layout'

interface Props {
  children: ReactNode
  type: string
}

export const NavigationLayout: React.FC<Props> = ({ children, type }) => {
  const router = useRouter()


  // const { isMobile } = useDesignSystem()

  const goTo = (url: string) => {
    router.push(url)
  }


  let itemsLeftbar = [
    {
      key: '/home',
      label: 'Home',
      onClick: () => goTo('/home'),
    },

    {
      key: '/vault-allocations',
      label: 'Vault Allocations',
      onClick: () => goTo('/vault-allocations'),
    },

    {
      key: '/borrowing-history',
      label: 'Borrowing History',
      onClick: () => goTo('/borrowing-history'),
    },

    {
      key: '/transaction-history',
      label: 'Transaction History',
      onClick: () => goTo('/transaction-history'),
    },

    {
      key: '/investment-strategy',
      label: 'Investment Strategies',
      onClick: () => goTo('/investment-strategy'),
    },

    {
      key: '/pools',
      label: 'Lend/Borrow Pools',
      onClick: () => goTo('/pools'),
    },
  ]

  let itemsUser:any[] = []

  let itemsTopbar:any[] = []

  // let itemsSubNavigation = [
  //   {
  //     key: '/home',
  //     label: 'Home',
  //   },

  //   {
  //     key: '/properties/:propertyId',
  //     label: 'Property Details',
  //   },

  //   {
  //     key: '/vault',
  //     label: 'Vault Allocations',
  //   },

  //   {
  //     key: '/borrowing-history',
  //     label: 'Borrowing History',
  //   },

  //   {
  //     key: '/transaction-history',
  //     label: 'Transaction History',
  //   },

  //   {
  //     key: '/borrowing-limits',
  //     label: 'Investment Strategies',
  //   },
  // ]

  // let itemsMobile = [
  //   {
  //     key: 'profile',
  //     label: 'Profile',
  //     // onClick: () => goTo(RouterObject.route.PROFILE),
  //   },
  //   {
  //     key: 'notifications',
  //     label: 'Notifications',
  //     // onClick: () => goTo(RouterObject.route.NOTIFICATIONS),
  //   },
  //   ...itemsTopbar,
  //   ...itemsLeftbar,
  // ]

  const isLeftbar =
    (itemsLeftbar.length > 0 || itemsUser.length > 0) && type == 'bar'
    

  // if (!authentication.isLoggedIn) {
  //   itemsLeftbar = []
  //   itemsUser = []
  //   itemsTopbar = []
  //   itemsSubNavigation = []
  //   itemsMobile = []
  // }

  return (
    <DesignSystem.Provider>
      <Layout>
        <Row
          style={{
            height: '100vh',
            width: '100vw',
          }}
        >
          {isLeftbar && (
            <Col>
              <Leftbar
                items={itemsLeftbar}
                itemsUser={itemsUser}
                logo={<Logo className="m-2" />}
              />
            </Col>
          )}

          <Col
            style={{
              flex: 1,
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden',
            }}
          >
            {/* <Topbar
              isMobile={isMobile}
              isLoggedIn={authentication.isLoggedIn}
              items={itemsTopbar}
              itemsMobile={itemsMobile}
              logo={!isLeftbar && <Logo width={40} height={40} />}
            /> */}

            <Col
              style={{
                flex: 1,
                overflowY: 'auto',
                overflowX: 'hidden',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
              }}
            >
              {/* <SubNavigation items={itemsSubNavigation} /> */}

              {children}
            </Col>
          </Col>
        </Row>
      </Layout>
    </DesignSystem.Provider>
  )
}
